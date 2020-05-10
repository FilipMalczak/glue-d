module foo.config;

import glued.application;

import foo.operators;

@Configuration
class Config {
    
    @Component
    Operator multiply(){
        return new Multiply();
    }
    
    @Component
    Power power(Operator multiply){
        return new Power(multiply);
    }
}

// ignored, because not annotated as Configuration
// it wires types in different way, so tests for api should fail if this gets
// registered
class IgnoredConfig {
    @Component
    Multiply multiply(){
        return new Multiply();
    }
}
