import sys, os
import collections

def flatten(an_iterable):
    result = []
    for each in an_iterable:
        if isinstance(each, collections.Iterable) and not isinstance(each, str):
            result.extend(flatten(each))
        else:
            result.append(each)
    return result

available_modules = {
    'core' : '../../../generic/forth/core.forth',
    'punit' : '../../../generic/forth/punit.forth',
    'test' : '../../../generic/forth/test.forth',
    'ringbuf' : '../../../generic/forth/ringbuf.forth',
    'gpio' : '../forth/gpio.forth',
    'event' : '../forth/event.forth',
    'wifi' : '../forth/wifi.forth',
    'ssd1306-spi' : '../forth/ssd1306-spi.forth',
    'font5x7' : '../forth/font5x7.forth',
    'netcon' : '../forth/netcon.forth',
    'netcon-test' : '../forth/netcon-test.forth',
    'tasks' : '../forth/tasks.forth',
    'mailbox' : '../forth/mailbox.forth',
    'tcp-repl' : '../forth/tcp-repl.forth',
    'flash' : '../forth/flash.forth',
    'turnkey' : '../forth/turnkey.forth',
    'dht22' : '../forth/dht22.forth',
    'ping' : '../forth/ping.forth',
    'sonoff' : '../forth/sonoff.forth',
    'ntp' : '../forth/ntp.forth',
    'example-game-of-life' : '../forth/examples/example-game-of-life.forth',
    'example-ircbot' : '../forth/examples/example-ircbot.forth',
    'example-philips-hue' : '../forth/examples/example-philips-hue.forth',
    'example-philips-hue-lightswitch' : '../forth/examples/example-philips-hue-lightswitch.forth',
    'example-philips-hue-pir' : '../forth/examples/example-philips-hue-pir.forth',
    'example-philips-hue-clap' : '../forth/examples/example-philips-hue-clap.forth',
    'example-geekcreit-rctank' : '../forth/examples/example-geekcreit-rctank.forth',
    'example-http-server' : '../forth/examples/example-http-server.forth',
    'example-dht22-data-logger' : '../forth/examples/example-dht22-data-logger.forth',
    'example-buzzer-mario' : '../forth/examples/example-buzzer-mario.forth',
    'example-buzzer-starwars' : '../forth/examples/example-buzzer-starwars.forth',
    'example-stock-price' : '../forth/examples/example-stock-price.forth',
}

dependencies = {
    'core' : [],
    'punit' : ['core'],
    'test' : ['core', 'punit'],
    'ringbuf' : ['core'],
    'gpio' : ['core'],
    'event' : ['core', 'tasks'],
    'wifi' : ['core'],
    'ssd1306-spi' : ['core', 'gpio'],
    'font5x7' : ['core'],
    'netcon' : ['core', 'tasks'],
    'netcon-test' : ['netcon', 'punit', 'wifi', 'mailbox'],
    'tasks' : ['core'],
    'mailbox' : ['ringbuf'],
    'flash' : ['core'],
    'turnkey' : ['core'],
    'dht22' : ['core', 'gpio'],
    'ping': ['core', 'gpio'],
    'sonoff': ['core', 'gpio'],
    'ntp': ['core', 'netcon'],
    'tcp-repl' : ['core', 'netcon', 'wifi', 'mailbox'],
    'example-game-of-life' : ['core', 'ssd1306-spi'],
    'example-ircbot' : ['core', 'netcon', 'tasks', 'gpio'],
    'example-philips-hue' : ['core', 'netcon'],
    'example-philips-hue-lightswitch' : ['example-philips-hue', 'tasks', 'gpio', 'event'],
    'example-philips-hue-pir' : ['example-philips-hue', 'tasks', 'gpio', 'event'],    
    'example-philips-hue-clap' : ['example-philips-hue', 'tasks', 'gpio', 'event'],
    'example-geekcreit-rctank' : ['core', 'tasks', 'gpio', 'event', 'wifi', 'netcon', 'tcp-repl', 'ping'],
    'example-http-server' : ['core', 'netcon', 'wifi', 'mailbox'],
    'example-dht22-data-logger' : ['dht22', 'netcon', 'turnkey'],
    'example-buzzer-mario' : ['gpio'],
    'example-buzzer-starwars' : ['gpio'],
    'example-stock-price' : ['netcon', 'ssd1306-spi', 'font5x7', 'wifi', 'gpio', 'turnkey'],
}

def collect_dependecies(modules):
    def _deps(modules, result=[]):
        for mod in modules:
            transitive = []
            _deps(dependencies[mod], result=transitive)
            if transitive: 
                result.append(transitive)
            if dependencies[mod]: 
                result.append(dependencies[mod])
            result.append([mod])
    print('Analyzing dependencies..')
    result = []
    _deps(modules, result=result)
    unique_result = []
    for each in flatten(result):
        if each not in unique_result: unique_result.append(each)
    print('Modules with dependencies: %s' % unique_result)
    return unique_result
    
def module_paths(modules):
    try:
        return [available_modules[each] for each in modules]
    except KeyError as e:
        print('Module not found: ' + str(e))
        sys.exit()
      
class Uber:
    def __init__(self, modules, app, block_format, max_line_len):
        self.modules = modules
        self.app = app
        self.block_format = block_format
        self.max_line_len = max_line_len
      
    def make(self, output_file, flash_space):
        uber = self.generate()
        if self.block_format: uber = self.pad(uber)
        self.check(uber, flash_space)
        self.save(uber, output_file)

    def generate(self):
        contents = [open(each).read() for each in module_paths(self.modules)]
        if self.app:
            with open(self.app) as f: contents.append(f.read())
        contents.append('\nstack-show ')
        contents.append(chr(0))
        return '\n'.join(contents)
    
    def pad(self, uber):
        """ This is for the block screen editor. A screen = 128 columns and 32 rows """
        def pad_line(line):
            return line + (' ' * (self.max_line_len - len(line)))
        return '\n'.join([pad_line(line) for line in uber.split('\n')])
                 
    def check(self, uber, flash_space):
        if len(uber) > flash_space:
            print('Not enough space in flash')
            sys.exit()
        if any(len(line) > self.max_line_len for line in uber.split('\n')):
            print('Input overflow at line: "%s"' % [line for line in uber.split('\n') if len(line) >= self.max_line_len][0])
            sys.exit()

    def save(self, uber, output_file):
        with open(output_file, 'wt') as f: f.write(uber)

class Help:
    def __init__(self, available_modules):
        self.available_modules = available_modules

    def show(self):
        print('Usage: modules.py [--block-format] [--app /path/to/app.forth] [modul1] [modul2] .. [modulN] ')
        print('Available modules:')
        for each in self.available_modules.keys():
            print('    * ' + each)
        sys.exit()
    
class CommandLine:
    @classmethod
    def parse(self, argv, help):
        if len(argv) < 2: help.show()
        block_format = self.check_block_format(argv)
        app, chosen_modules = self.parse_params(argv)
        return CommandLine(chosen_modules, app, block_format, help)
    
    @classmethod
    def check_block_format(self, argv):
        if '--block-format' in argv:
            argv.remove('--block-format')
            return True
        else:
            return False
    
    @classmethod
    def parse_params(self, argv):
        return (argv[2], argv[3:]) if argv[1] == '--app' else (None, argv[1:])
    
    def __init__(self, chosen_modules, app, block_format, help):
        self.chosen_modules = chosen_modules
        self.app = app
        self.block_format = block_format
        self.help = help

    def validate(self, available_modules):
        print(self)
        if self.app and not os.path.isfile(self.app):
            print('Application %s does not exist' % self.app)
            self.help.show()    
        if not set(self.chosen_modules).issubset(available_modules.keys()):
            print('No such module')
            self.help.show()
        
    def __str__(self):
        return 'Chosen modules %s. App: %s. Block format: %s' % (self.chosen_modules, self.app, self.block_format)
    
UBER_NAME = 'uber.forth'
    
if __name__ == '__main__':
    if os.path.isfile(UBER_NAME): os.remove(UBER_NAME)    
    command = CommandLine.parse(sys.argv, Help(available_modules))    
    command.validate(available_modules)
    uber = Uber(
        collect_dependecies(command.chosen_modules), 
        app=command.app, 
        block_format=command.block_format,
        max_line_len=128 - len(os.linesep))
    uber.make(output_file=UBER_NAME, flash_space=180*1024)
    print('%s ready. Use flash <COMPORT> to install' % UBER_NAME)
