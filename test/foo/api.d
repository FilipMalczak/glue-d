module foo.api;

import glued.stereotypes;
import glued.context; //ditto from operators

import foo.operators;

@Component
class Api {
    //@Autowire!(Power)() would work as well
    @Autowire!(Power)
    Operator power;
    
    //@Autowire!()() would work as well
    @Autowire!()
    Operator multiply;
    
    //@Autowire() WOULD NOT work; it would see sole candidate Autowire!()(), but wouldn't resolve to it
    @Autowire
    Add add;

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
