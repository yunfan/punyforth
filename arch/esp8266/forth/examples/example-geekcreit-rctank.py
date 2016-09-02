import pygame, socket

# TODO: # speed up/down

class Tank:
    directions = {        
        (0, -1) : b'F',
        (0, 1)  : b'B',
        (-1, 0) : b'L',
        (1, 0)  : b'R',
        (0,0)   : b'S'
    }    
    def __init__(self, address):
        self.address = address
        self.socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.engine_started = False
        
    def move(self, direction):
        if direction in Tank.directions:
            self._command(Tank.directions[direction])
                
    def toggle_engine(self):
        self._command(b'H' if self.engine_started else b'E')
        self.engine_started = not self.engine_started
        
    def _command(self, cmd):
        print('Sending command %s to: %s' % (cmd, self.address))
        self.socket.sendto(cmd, self.address)

class Gamepad:
    def __init__(self, joystick, engine_button, horizontal_axis, vertical_axis):
        pygame.init()
        pygame.joystick.init()
        self.joystick = pygame.joystick.Joystick(joystick)
        self.horizontal_axis, self.vertical_axis = horizontal_axis, vertical_axis
        self.engine_button = engine_button
        print("Initializing joystick %s" % self.joystick.get_name())
        self.joystick.init()
        
    def process_input(self, robot):
        print('waiting for input')
        while True:
            for event in pygame.event.get():
                direction = [self.joystick.get_axis(self.horizontal_axis), self.joystick.get_axis(self.vertical_axis)]
                robot.move(tuple(map(round, direction)))
                if self.joystick.get_button(self.engine_button) == 1:
                    robot.toggle_engine()
    
gamepad = Gamepad(joystick=0, engine_button=0, horizontal_axis=0, vertical_axis=1)
gamepad.process_input(Tank(('192.168.0.22', 8000)))    
