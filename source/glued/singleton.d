module glued.singleton;

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

//fixme this got ugly pretty fast :/
template SharedRoot(T) if (is(T == class)) {
    struct SharedRoot { 
        private shared static T instance;
        private shared static bool initialized = false;

        private shared T _value;
        
        alias _value this;
        
        public static SharedRoot get(){
            //todo if !initialized
            return SharedRoot(instance);
        }
        
        @property
        public shared T value(){
            return this._value;
        }
                
        public static void initialize(shared T instance){
            if (!initialized) 
            {
                SharedRoot.initialized  = true;
                SharedRoot.instance = instance;
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

