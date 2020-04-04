module glued.singleton;

//todo is this a good idea?
template Root(T) if (is(T == class)) {
    struct Root { 
        private static T instance;
        private static bool initialized = false;

        private T _value;
        
        alias _value this;
        
        public static Root get(){
            //todo if !initialized
            return Root(instance);
        }
        
        @property
        public T value(){
            return this._value;
        }
                
        public static void initialize(T instance){
            if (!initialized) 
            {
                Root.initialized  = true;
                Root.instance = instance;
            } else
            //todo
                throw new Exception("already initialized!");
        }
    }
}

mixin template HasSingleton() {
    static this(){
        Root!(typeof(this)).initialize(new typeof(this)());
    }
    
    static typeof(this) get(){
        return Root!(typeof(this)).get().value;
    }
}

