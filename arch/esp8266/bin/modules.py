import sys, os
from compiler.ast import flatten

FLASH_SPACE = 0x20000 - 0x18000 

available_modules = {
    'core' : '../../../generic/forth/core.forth',
    'ringbuf' : '../../../generic/forth/ringbuf.forth',
    'gpio' : '../forth/gpio.forth',
    'wifi' : '../forth/wifi.forth',
    'ssd1306-spi' : '../forth/ssd1306-spi.forth',
    'netconn' : '../forth/netconn.forth',
    'tasks' : '../forth/tasks.forth',
    'example-game-of-life' : '../forth/examples/example-game-of-life.forth',
    'exampe-consumer' : '../forth/examples/exampe-consumer.forth'
}

dependencies = {
    'core' : [],
    'ringbuf' : ['core'],
    'gpio' : ['core'],
    'wifi' : ['core'],
    'ssd1306-spi' : ['core', 'gpio'],
    'netconn' : ['core'],
    'tasks' : ['core', 'ringbuf'],    
    'example-game-of-life' : ['core', 'ssd1306-spi'],
    'example-consumer' : ['core', 'tasks']
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