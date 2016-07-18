import sys, os
from compiler.ast import flatten

FLASH_SPACE = 0x20000 - 0x18000 

available_modules = {
    'core' : '../../../generic/forth/core.forth',
    'punit' : '../../../generic/forth/punit.forth',
    'test' : '../../../generic/forth/test.forth',
    'ringbuf' : '../../../generic/forth/ringbuf.forth',
    'gpio' : '../forth/gpio.forth',
    'wifi' : '../forth/wifi.forth',
    'ssd1306-spi' : '../forth/ssd1306-spi.forth',
    'netcon' : '../forth/netcon.forth',
    'tasks' : '../forth/tasks.forth',
    'tcp-repl' : '../forth/tcp-repl.forth',
    'flash' : '../forth/flash.forth',
    'example-game-of-life' : '../forth/examples/example-game-of-life.forth',
    'example-ircbot' : '../forth/examples/example-ircbot.forth',
    'example-philips-hue' : '../forth/examples/example-philips-hue.forth',
    'example-philips-hue-lightswitch' : '../forth/examples/example-philips-hue-lightswitch.forth',
    'example-http-server' : '../forth/examples/example-http-server.forth',    
}

dependencies = {
    'core' : [],
    'punit' : ['core'],
    'test' : ['core', 'punit'],
    'ringbuf' : ['core'],
    'gpio' : ['core'],
    'wifi' : ['core'],
    'ssd1306-spi' : ['core', 'gpio'],
    'netcon' : ['core', 'tasks'],
    'tasks' : ['core', 'ringbuf'],
    'flash' : ['core'],
    'tcp-repl' : ['core', 'netcon', 'wifi'],
    'example-game-of-life' : ['core', 'ssd1306-spi'],
    'example-ircbot' : ['core', 'netcon', 'tasks', 'gpio'],
    'example-philips-hue' : ['core', 'netcon'],
    'example-philips-hue-lightswitch' : ['example-philips-hue', 'tasks', 'gpio'],
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
    contents.append(chr(0))
    return '\n'.join(contents)
      
if __name__ == '__main__':
    if len(sys.argv) == 1: print_help()        
    chosen_modules = sys.argv[1:]        
    print('Chosen modules %s' % chosen_modules)        
    uber = uber_module(collect_dependecies(chosen_modules))           
    if len(uber) > FLASH_SPACE:
        print('Not enough space in flash')
        sys.exit()
    with open('uber.forth', 'wt') as f: f.write(uber)
