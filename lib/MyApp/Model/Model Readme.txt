
Models must be usable from utility scripts that will probably not be creating 
MyApp objects.

Therefore, models must not attempt to access "wxTheApp".  

If a model needs access to configuration settings held in the Bread::Board 
container, they'll need to make their own containers:

    has 'bb'  => (
        is          => 'ro',
        isa         => 'MyApp::Model::Container',  
        lazy        => 1,
        default     => sub{ MyApp::Model::Container->new(name => 'update help') },
        handles => {
            resolve => 'resolve',
        }
    );

