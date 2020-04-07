module foo.api;

import glued.stereotypes;
import poodinis;

import foo.operators;

@Register
class Api {
    @Autowire!(Power)
    private Operator power;
    
    @Autowire
    private Operator multiply;
    
    @Autowire
    private Add add;

    /**
     * foo(x) = x^2 + 5x + 3
     */
    int foo(int x){
        return add.apply(
            add.apply(
                power.apply(x, 2),
                multiply.apply(5, x)
            ),
            3
        );
    } 
}
