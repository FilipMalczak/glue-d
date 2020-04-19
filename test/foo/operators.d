module foo.operators;

import glued.context.annotations;

interface Operator {
    int apply(int a, int b);
}

@Component
class Add: Operator {
    override int apply(int a, int b){
        return a+b;
    }
}

class Multiply: Operator {
    override int apply(int a, int b){
        return a*b;
    }
}

class Power: Operator {
    private Operator multiply;
    
    @Constructor //fixme is in context, where should it be? awkward import
    this(Operator multiply){
        this.multiply = multiply;
    }
    
    override int apply(int a, int b){
        int result = 1;
        foreach (i; 0 .. b)
            result = multiply.apply(result, a);
        return result;
    }
}
