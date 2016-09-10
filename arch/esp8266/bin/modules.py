import sys, os
from compiler.ast import flatten

FLASH_SPACE = 180*1024
UBER_NAME = 'uber.forth'
MAX_LINE_LEN = 127

available_modules = {
    'core' : '../../../generic/forth/core.forth',
    'punit' : '../../../generic/forth/punit.forth',
    'test' : '../../../generic/forth/test.forth',
    'ringbuf' : '../../../generic/forth/ringbuf.forth',
    'gpio' : '../forth/gpio.forth',
    'event' : '../forth/event.forth',
    'wifi' : '../forth/wifi.forth',
    'ssd1306-spi' : '../forth/ssd1306-spi.forth',
    'netcon' : '../forth/netcon.forth',
    'netcon-test' : '../forth/netcon-test.forth',
    'tasks' : '../forth/tasks.forth',
    'tcp-repl' : '../forth/tcp-repl.forth',
    'flash' : '../forth/flash.forth',
    'dht22' : '../forth/dht22.forth',
    'example-game-of-life' : '../forth/examples/example-game-of-life.forth',
    'example-ircbot' : '../forth/examples/example-ircbot.forth',
    'example-philips-hue' : '../forth/examples/example-philips-hue.forth',
    'example-philips-hue-lightswitch' : '../forth/examples/example-philips-hue-lightswitch.forth',
    'example-philips-hue-pir' : '../forth/examples/example-philips-hue-pir.forth',
    'example-philips-hue-clap' : '../forth/examples/example-philips-hue-clap.forth',
    'example-geekcreit-rctank' : '../forth/examples/example-geekcreit-rctank.forth',
    'example-http-server' : '../forth/examples/example-http-server.forth',    
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
    'netcon' : ['core', 'tasks'],
    'netcon-test' : ['netcon', 'punit', 'wifi'],
    'tasks' : ['core', 'ringbuf'],
    'flash' : ['core'],
    'dht22' : ['core', 'gpio'],
    'tcp-repl' : ['core', 'netcon', 'wifi'],
    'example-game-of-life' : ['core', 'ssd1306-spi'],
    'example-ircbot' : ['core', 'netcon', 'tasks', 'gpio'],
    'example-philips-hue' : ['core', 'netcon'],
    'example-philips-hue-lightswitch' : ['example-philips-hue', 'tasks', 'gpio', 'event'],
    'example-philips-hue-pir' : ['example-philips-hue', 'tasks', 'gpio', 'event'],    
    'example-philips-hue-clap' : ['example-philips-hue', 'tasks', 'gpio', 'event'],
    'example-geekcreit-rctank' : ['core', 'tasks', 'gpio', 'event', 'wifi', 'netcon', 'tcp-repl'],
    'example-http-server' : ['core', 'netcon', 'wifi']
}

def print_help():
    print('Usage: %s [--app /path/to/app.forth] [modul1] [modul2] .. [modulN] ' % (os.path.basename(sys.argv[0])))
    print('Available modules:')
    for each in available_modules.keys():
        print('    * ' + each)
    sys.exit()

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
      
def uber_module(modules, app=None):
    contents = [open(each).read() for each in module_paths(modules)]
    if app:
        with open(app) as f: contents.append(f.read())
    contents.append('\nstack-show ')
    contents.append(chr(0))
    return '\n'.join(contents)
      
def check_uber(uber):
    if len(uber) > FLASH_SPACE:
        print('Not enough space in flash')
        sys.exit()
    if any(len(line) >= MAX_LINE_LEN for line in uber.split('\n')):
        print('Input overflow at line: "%s"' % [line for line in uber.split('\n') if len(line) >= MAX_LINE_LEN][0])
        sys.exit()
        
if __name__ == '__main__':
    if os.path.isfile(UBER_NAME): os.remove(UBER_NAME)
    if len(sys.argv) == 1: print_help()
    if sys.argv[1] == '--app':
        app = sys.argv[2]        
        if not os.path.isfile(app):
            print('Application %s does not exist' % app)
            print_help()
        print("Application: %s" % app)            
        chosen_modules = sys.argv[3:]
    else:
        app = None
        chosen_modules = sys.argv[1:]
    print('Chosen modules %s' % chosen_modules)
    if not set(chosen_modules).issubset(available_modules.keys()):
        print('No such module')
        print_help()
    uber = uber_module(collect_dependecies(chosen_modules), app=app)
    check_uber(uber)
    with open(UBER_NAME, 'wt') as f: f.write(uber)
    print('%s ready. Use flash <COMPORT> to install' % UBER_NAME)