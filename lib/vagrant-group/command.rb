module VagrantPlugins
  module Group
    class Command < Vagrant.plugin(2, :command)

      COMMANDS = %w(up halt destroy provision reload hosts suspend resume)

      def self.synopsis
        'runs vagrant command on specific group of VMs'
      end # self.synopsis

      def execute
        options = {
          provision_ignore_sentinel: false, # otherwise reload command does provision
        }
        opts = OptionParser.new do |o|
          o.banner = sprintf('Usage: vagrant group <%s> <group-name>', COMMANDS.join('|'))
          o.separator ''

          o.on('-h', '--help', 'Print this help') do
            safe_puts(opts.help)
            return nil
          end

          o.on('-f', '--force', 'Do action (destroy, halt) without confirmation.') do
            options[:force_confirm_destroy] = true
            options[:force_halt]            = true
          end

          o.on(nil, '--provision', 'Enable provisioning (up, reload).') do
            options[:provision_ignore_sentinel] = true
          end
        end

        argv = parse_options(opts)

        action, pattern = argv[0], argv[1]

        if !pattern || !action || !COMMANDS.include?(action)
          safe_puts(opts.help)
          return nil
        end

        groups = find_groups(pattern)
        if groups.length == 0
          @env.ui.error('No groups matched the pattern given.')
          return nil
        end

        if action == 'hosts'
          groups.each do |group|
            print_hosts(group)
          end
        elsif
          groups.each do |group|
            do_action(action, options, group)
          end
        end
      end # execute

      def print_hosts(group)
        @env.ui.info(sprintf('Hosts in %s group:', group))

        with_target_vms() do |machine|
          if machine.config.group.groups.has_key?(group)
            if machine.config.group.groups[group].to_a.include? machine.name.to_s
              @env.ui.info(sprintf(' - %s', machine.name))
            end
          elsif
            @env.ui.warn('No hosts associated.')
            break
          end
        end
      end # print_hosts

      def do_action(action, options, group)
        with_target_vms() do |machine|
          if machine.config.group.groups.has_key?(group)
            if machine.config.group.groups[group].include? machine.name.to_s
              machine.action(action, **options)
            end
          end
        end
      end # do_action

      def all_groups
        groups = Set.new

        with_target_vms() do |machine|
          machine.config.group.groups.to_h.each do |group_name, hosts|
            groups << group_name
          end
        end

        return groups.to_a
      end # all_groups

      def find_groups(pattern)
        groups = []

        if pattern[0] == '/' && pattern[-1] == '/'
          reg = Regexp.new(pattern[1..-2])
          all_groups.each do |item|
            groups << item if item.match(reg)
          end
        else
          all_groups.each do |item|
            groups << item if item == pattern
          end
        end

        groups
      end # find_groups
    end # Command
  end # Group
end # VagrantPlugins
