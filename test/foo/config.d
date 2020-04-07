module foo.config;

import poodinis;
import glued.stereotypes;

import foo.operators;

@Configuration
class Config {
    
    @Component
    @RegisterByType!Operator
    Multiply multiply(){
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
class IgnoredConfig: ApplicationContext {
    public override void registerDependencies(shared(DependencyContainer) container) {
        container.register!(Operator, Power);
    }
    
    @Component
    Multiply multiply(){
        return new Multiply();
    }
}
