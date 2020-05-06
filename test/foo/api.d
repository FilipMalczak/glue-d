module foo.api;

import glued.application; //ditto from operators

import foo.operators;

interface FooWithExpected {
    int foo(int x);
    int expected(int x);
}

@Component
class FooByField: FooWithExpected
{
    //@Autowire!(Power)() would work as well
    @Autowire!(Power)
    Operator power;
    
    //@Autowire!()() would work as well
    @Autowire!()
    Operator multiply;
    
    //@Autowire() WOULD NOT work; it would see sole candidate Autowire!()(), but wouldn't resolve to it
    @Autowire
    Add add;

    @DontInject
    this(){
        assert(false, "If this constructor was called, then something is seriously effed up");
    }

    int foo(int x)
    {
        return add.apply(
            add.apply(
                power.apply(x, 2),
                multiply.apply(5, x)
            ),
            3
        );
    }
    
    int expected(int x)
    {
        return x*x + 5*x + 3;
    }
}

@Component
class FooByConstructor: FooWithExpected
 {
    private Operator power;
    
    private Operator multiply;
    
    private Add add;
    
    this(){
        assert(false, "If this constructor was called, then something is seriously effed up");
    }
    
    @Constructor
    this(Power power, Operator multiply, Add add){
        this.power = power;
        this.multiply = multiply;
        this.add = add;
    }

    int foo(int x)
    {
        return add.apply(
            add.apply(
                power.apply(x, 3),
                multiply.apply(7, x)
            ),
            4
        );
    }
    
    int expected(int x)
    {
        return x*x*x + 7*x + 4;
    }
}

@Component
class FooByProperty: FooWithExpected
{
    private Operator power;
    
    private Operator multiply;
    
    private Add add;
    
    @Autowire!Power
    @property void powerProp(Operator p){ power = p; }
    
    @Autowire!()
    @property void multiplyProp(Operator m) { multiply = m; }
    
    @Autowire
    @property void addProp(Add a) { add = a; }
    
    @DontInject
    this(){
        assert(false, "If this constructor was called, then something is seriously effed up");
    }

    int foo(int x)
    {
        return add.apply(
            add.apply(
                power.apply(x, 2),
                multiply.apply(2, x)
            ),
            2
        );
    }
    
    int expected(int x)
    {
        return x*x + 2*x + 2;
    }
}

@Component
class MixedFoo: FooWithExpected
{
    @Autowire!Power
    Operator power;
    
    private Operator multiply;
    
    private Add add;
    
    @Autowire
    @property void addProp(Add a) { add = a; }
    
    this(){
        assert(false, "If this constructor was called, then something is seriously effed up");
    }
    
    @Constructor
    this(Operator multiply){
        this.multiply = multiply;
    }

    int foo(int x)
    {
        return add.apply(
            add.apply(
                power.apply(x, 2),
                multiply.apply(2, x)
            ),
            2
        );
    }
    
    int expected(int x)
    {
        return x*x + 2*x + 2;
    }
}

