import sys, os
from compiler.ast import flatten

FLASH_SPACE = 180*1024

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
    print('Usage: %s [modul1] [modul2] .. [modulN] ' % (os.path.basename(sys.argv[0])))
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
      
def uber_module(modules):
    contents = [open(each).read() for each in module_paths(modules)]
    contents.append('\nstack-show ')
    contents.append(chr(0))
    return '\n'.join(contents)
      
if __name__ == '__main__':
    if len(sys.argv) == 1: print_help()        
    chosen_modules = sys.argv[1:]
    print('Chosen modules %s' % chosen_modules)
    if not set(chosen_modules).issubset(available_modules.keys()):
        print('No such module')
        print_help()
    uber = uber_module(collect_dependecies(chosen_modules))           
    if len(uber) > FLASH_SPACE:
        print('Not enough space in flash')
        sys.exit()
    with open('uber.forth', 'wt') as f: f.write(uber)
