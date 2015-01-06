require 'sparkle_formation'
require 'pathname'
require 'knife-cloudformation'

class Chef
  class Knife
    # Cloudformation create command
    class CloudformationCreate < Knife

      include KnifeCloudformation::Knife::Base
      include KnifeCloudformation::Knife::Template
      include KnifeCloudformation::Knife::Stack

      banner 'knife cloudformation create NAME'

      option(:timeout,
        :short => '-t MIN',
        :long => '--timeout MIN',
        :description => 'Set timeout for stack creation',
        :proc => lambda {|val|
          Chef::Config[:knife][:cloudformation][:options][:timeout_in_minutes] = val
        }
      )
      option(:rollback,
        :short => '-R',
        :long => '--[no]-rollback',
        :description => 'Rollback on stack creation failure',
        :boolean => true,
        :default => true,
        :proc => lambda {|val| Chef::Config[:knife][:cloudformation][:options][:disable_rollback] = !val }
      )
      option(:capability,
        :short => '-C CAPABILITY',
        :long => '--capability CAPABILITY',
        :description => 'Specify allowed capabilities. Can be used multiple times.',
        :proc => lambda {|val|
          Chef::Config[:knife][:cloudformation][:options][:capabilities] ||= []
          Chef::Config[:knife][:cloudformation][:options][:capabilities].push(val).uniq!
        }
      )
      option(:notifications,
        :long => '--notification ARN',
        :description => 'Add notification ARN. Can be used multiple times.',
        :proc => lambda {|val|
          Chef::Config[:knife][:cloudformation][:options][:notification_ARNs] ||= []
          Chef::Config[:knife][:cloudformation][:options][:notification_ARNs].push(val).uniq!
        }
      )
      option(:print_only,
        :long => '--print-only',
        :description => 'Print template and exit'
      )
      option(:apply_stacks,
        :long => '--apply-stack NAME_OR_ID',
        :description => 'Autofill parameters using existing stack outputs. Can be used multiple times',
        :proc => lambda {|val|
          Chef::Config[:knife][:cloudformation][:create] ||= Mash.new
          Chef::Config[:knife][:cloudformation][:create][:apply_stacks] ||= []
          Chef::Config[:knife][:cloudformation][:create][:apply_stacks].push(val).uniq!
        }
      )

      # Run the stack creation command
      def _run
        name = name_args.first
        unless(name)
          ui.fatal "Formation name must be specified!"
          exit 1
        end
        if(Chef::Config[:knife][:cloudformation][:template])
          file = Chef::Config[:knife][:cloudformation][:template]
        else
          file = load_template_file
          nested_stacks = file.delete('sfn_nested_stack')
        end
        ui.info "#{ui.color('Cloud Formation:', :bold)} #{ui.color('create', :green)}"
        stack_info = "#{ui.color('Name:', :bold)} #{name}"
        if(Chef::Config[:knife][:cloudformation][:path])
          stack_info << " #{ui.color('Path:', :bold)} #{Chef::Config[:knife][:cloudformation][:file]}"
          if(Chef::Config[:knife][:cloudformation][:disable_processing])
            stack_info << " #{ui.color('(not pre-processed)', :yellow)}"
          end
        end

        unless(config[:print_only])
          ui.info "  -> #{stack_info}"
        end

        if(nested_stacks)

          if(config[:print_only])
            ui.info _format_json(translate_template(stack.template))
            exit 0
          end

          # @todo move this init into setup
          Chef::Config[:knife][:cloudformation][:create] ||= Mash.new
          Chef::Config[:knife][:cloudformation][:create][:apply_stacks] ||= []

          orig_params = Chef::Config[:knife][:cloudformation][:options][:parameters]

          file['Resources'].each do |stack_resource_name, stack_resource|

            nested_stack_name = "#{name}-#{stack_resource_name}"
            nested_stack_template = stack_resource['Properties']['Stack']
            Chef::Config[:knife][:cloudformation][:options][:parameters] = orig_params

            nested_stack_runner = Chef::Knife::CloudformationCreate.new
            nested_stack_runner.name_args.push(nested_stack_name)
            Chef::Config[:knife][:cloudformation][:template] = nested_stack_template
            nested_stack_runner.run
            Chef::Config[:knife][:cloudformation][:create][:apply_stacks].push(nested_stack_name).uniq!
            Chef::Config[:knife][:cloudformation][:template] = nil
            provider.connection.stacks.reload

          end

        else

          stack = provider.connection.stacks.build(
            Chef::Config[:knife][:cloudformation][:options].dup.merge(
              :name => name,
              :template => file
            )
          )

          apply_stacks!(stack)
          stack.template = KnifeCloudformation::Utils::StackParameterScrubber.scrub!(stack.template)

          if(config[:print_only])
            ui.info _format_json(translate_template(stack.template))
            exit 0
          end

          populate_parameters!(stack.template)
          stack.parameters = Chef::Config[:knife][:cloudformation][:options][:parameters]

          stack.template = translate_template(stack.template)
          stack.save

        end

        if(Chef::Config[:knife][:cloudformation][:poll])
          poll_stack(stack.name)
          stack = provider.connection.stacks.get(name)

          if(stack.reload.success?)
            ui.info "Stack create complete: #{ui.color('SUCCESS', :green)}"
            knife_output = Chef::Knife::CloudformationDescribe.new
            knife_output.name_args.push(name)
            knife_output.config[:outputs] = true
            knife_output.run
          else
            ui.fatal "Create of new stack #{ui.color(name, :bold)}: #{ui.color('FAILED', :red, :bold)}"
            ui.info ""
            knife_inspect = Chef::Knife::CloudformationInspect.new
            knife_inspect.name_args.push(name)
            knife_inspect.config[:instance_failure] = true
            knife_inspect.run
            exit 1
          end
        else
          ui.warn 'Stack state polling has been disabled.'
          ui.info "Stack creation initialized for #{ui.color(name, :green)}"
        end
      end

      # Apply any defined remote stacks
      #
      # @param stack [Miasma::Models::Orchestration::Stack]
      # @return [Miasma::Models::Orchestration::Stack]
      def apply_stacks!(stack)
        remote_stacks = Chef::Config[:knife][:cloudformation].
          fetch(:create, {}).fetch(:apply_stacks, [])
        remote_stacks.each do |stack_name|
          remote_stack = provider.connection.stacks.get(stack_name)
          if(remote_stack)
            stack.apply_stack(remote_stack)
          else
            ui.error "Failed to apply requested stack. Unable to locate. (#{stack_name})"
            exit 1
          end
        end
        stack
      end

    end
  end
end
