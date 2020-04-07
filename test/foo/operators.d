module foo.operators;

import glued.stereotypes;

interface Operator {
    int apply(int a, int b);
}

@Register
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
