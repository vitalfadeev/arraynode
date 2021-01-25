mixin template ArrayNode( T )
{
    T   parent;
    T[] childs;


    import std.traits : isCallable;


    // childs
    T firstChild()
    {
        if ( hasChilds )
            return childs[ 0 ];
        else
            return null;
    }

    T lastChild()
    {
        if ( hasChilds )
            return childs[ $-1 ];
        else
            return null;
    }

    // siblings
    T prevSibling()
    {
        // No Siblings when no Parent
        if ( parent is null )
        {
            return null;
        }

        //
        import std.algorithm : countUntil;
        auto pos = parent.childs.countUntil( this );

        // last
        if ( pos == 0 )
            return null;
        else
            return parent.childs[ pos - 1 ];

        //auto thisPtr = cast( T* ) this;

        //if ( thisPtr != parent.childs.ptr )
        //    return *( thisPtr - 1 );
        //else
        //    return null;
    }

    T nextSibling()
    {
        // No Siblings when no Parent
        if ( parent is null )
        {
            return null;
        }

        //
        import std.algorithm : countUntil;
        auto pos = parent.childs.countUntil( this );
        pos += 1;

        // last
        if ( pos == parent.childs.length )
            return null;
        else
            return parent.childs[ pos ];

        //T* thisPtr = cast( T* ) this;
        //thisPtr += 1;

        //// over last
        //if ( thisPtr == ( parent.childs.ptr + parent.childs.length ) )
        //    return null;
        //else // inside parent.childs
        //    return *thisPtr;
    }


    /** */
    pragma( inline )
    bool hasChilds()
    {
        return childs.length > 0;
    }


    /** */
    TC appendChild( TC )( TC child )
    {
        // Remove from parent
        if ( child.parent !is null )
        {
            child.removeFromParent();
        }

        child.parent = cast( T ) this;

        // Add
        childs ~= child;

        return child;
    }


    /** */
    TC insertChildBefore( TC )( TC child, T before )
    {
        import std.algorithm : countUntil;
        import std.array     : insertInPlace;

        // Remove from parent
        if ( child.parent !is null )
        {
            child.removeFromParent();
        }

        //
        child.parent = cast( T ) this;

        // Validate
        assert( before.parent is this );

        // Insert
        auto pos = childs.countUntil( before );

        assert( pos != -1 );

        //childs = childs[ 0 .. pos ] ~ child ~ childs[ pos .. $ ];
        childs.insertInPlace( pos, cast( typeof( childs ) ) [ child ] );

        return child;
    }


    /** */
    T insertChildAfter( T )( T child, T after )
    {
        import std.algorithm : countUntil;
        import std.array     : insertInPlace;

        // Remove from parent
        if ( child.parent !is null )
        {
            child.removeFromParent();
        }

        //
        child.parent = cast( Dragable ) this;

        // Validate
        assert( after.parent is this );

        // Insert
        auto pos = childs.countUntil( after );

        assert( pos != -1 );

        //childs = childs[ 0 .. pos ] ~ child ~ childs[ pos .. $ ];
        childs.insertInPlace( pos + 1, cast( typeof( childs ) ) [ child ] );

        return child;
    }


    /** */
    void removeFromParent()
    {
        assert( parent !is null );

        parent.removeChild( this );
    }


    /** */
    void removeChild( T c )
    {
        import std.algorithm : countUntil;
        import std.array     : replaceInPlace;

        assert( c !is null );

        // Parent
        c.parent = null;

        // Childs
        auto pos = childs.countUntil( c );

        assert( pos != -1 );

        //childs = childs[ 0 .. pos ] ~ childs[ pos+1 .. $ ];
        childs.replaceInPlace( pos, pos + 1, cast( typeof( childs ) ) [] );
    }


    /** */
    //void removeChild( T c )
    //{
    //    import std.algorithm : countUntil;

    //    assert( c !is null );

    //    // Parent
    //    c.parent = null;

    //    // Childs
    //    auto pos = childs.countUntil( c );

    //    assert( pos != -1 );

    //    childs = childs[ 0 .. pos ] ~ childs[ pos+1 .. $ ];
    //}


    /** */
    void removeChilds()
    {
        childs.length = 0;
    }


    /** */
    @property 
    size_t childsCount()
    {
        return childs.length;
    }


    /** */
    T findDeepest( FUNC )( FUNC func )
      if ( isCallable!FUNC )
    {
        foreach ( a; childs )
        {
            // Found
            if ( func( a ) )
            {
                // Test his childs. Recursive
                auto c = a.findDeepest( func );

                if ( c is null )
                    return a;
                else
                    return c;
            }
        }

        return null;
    }


    /** */
    T findFirst( alias IteratorFactory = inDepthIterator, FUNC )( FUNC func )
      if ( isCallable!FUNC )
    {
        foreach ( a; IteratorFactory() )
        {
            if ( func( a ) )
            {
                return a;
            }
        }

        return null;
    }


    /** */
    T findFirst( alias IteratorFactory = inDepthIterator, T )( T needle )
      if ( !isCallable!T )
    {
        foreach( a; IteratorFactory() )
        {
            if ( a == needle )
            {
                return a;
            }
        }

        return null;
    }


    /** */
    struct InDepthIterator
    {
        T   cur;
        T[] stack;

    public:
        // ForwardRange
        @property bool empty()    { return cur is null; }
        @property T    front()    { return cur; }

        void popFront()
        {
            import std.range.primitives : back;
            import std.range.primitives : popBack;

            // in depth
            if ( cur.hasChilds )
            {
                stack ~= cur;
                cur = cur.childs[ 0 ];
            }
            else // in width
            {
                cur = cur.nextSibling;         // RIGHT

            l1:
                // No next Sibling 
                if ( cur is null )
                {
                    // Go to Parent
                    if ( stack.length != 0 )
                    {
                        cur = stack.back;      // UP
                        stack.popBack();       // 
                        cur = cur.nextSibling; // RIGHT
                        goto l1;
                    }
                }
            }
        }

    }


    /** */
    auto inDepthIterator()
    {
        return InDepthIterator( cast( T ) this );
    }


    /** */
    auto inDepthChildIterator()
    {
        return InDepthIterator( this.firstChild );
    }



    /** */
    struct PlainIterator
    {
        T cur;

    public:
        // ForwardRange
        @property bool empty()    { return cur is null; }
        @property T    front()    { return cur; }

        void popFront()
        {
            cur = cur.nextSibling;         // RIGHT
        }
    }


    /** */
    auto plainChildIterator()
    {
        return PlainIterator( this.firstChild );
    }


    /** */
    struct ParentIterator
    {
        T cur;

    public:
        // ForwardRange
        @property bool empty()    { return cur is null; }
        @property T    front()    { return cur; }

        void popFront()
        {
            cur = cur.parent;              // UP
        }

    }


    /** */
    auto parentIterator()
    {
        return ParentIterator( this.parent );
    }


    /** */
    T findParent( FUNC )( FUNC func )
    {
        auto scan = this.parent;

        while ( scan !is null )
        {
            if ( func( scan ) )
            {
                return scan;
            }

            scan = scan.parent;
        }

        return null;
    }


    /** */
    T root()
    {
        auto scan = this.parent;

        while ( scan !is null )
        {
            if ( scan.parent is null )
            {
                return scan;
            }

            scan = scan.parent;
        }

        return null;
    }


    /** */
    CLS findParentClass( CLS )()
    {
        import ui.tools : instanceof;
        return cast( CLS ) findParent( ( T a ) => ( a.instanceof!CLS ) );
    }


    /** */
    void each( alias IteratorFactory = inDepthIterator, FUNC )( FUNC func )
    {
        foreach( a; IteratorFactory() )
        {
            func( a );
        }
    }


    /** */
    void eachChild( alias IteratorFactory = inDepthChildIterator, FUNC )( FUNC func )
    {
        foreach( a; IteratorFactory() )
        {
            func( a );
        }
    }


    /** */
    void eachChildPlain( FUNC )( FUNC func )
    {
        foreach( a; plainChildIterator() )
        {
            func( a );
        }
    }


    /** */
    void eachParent( alias IteratorFactory = parentIterator, FUNC )( FUNC func )
    {
        foreach( a; IteratorFactory() )
        {
            func( a );
        }
    }
}


///
unittest
{
    import std.format : format;


    class Node
    {
        mixin ArrayNode!( typeof(this) );

        void removeChild( Node child )
        {
            //
        }

        override
        string toString()
        {
            return format!"Node: 0x%s"( cast( void* ) this );
        }
    }

    //
    auto root     = new Node;
    auto child    = new Node;
    auto outsider = new Node;

    root.appendChild( child );

    // 
    uint counter;
    root.each( ( Node a ) => ( counter += 1 ) );
    assert( counter == 2 );

    // 
    uint childCounter;
    root.eachChild( ( Node a ) => ( childCounter += 1 ) );
    assert( childCounter == 1 );

    // 
    auto found = root.findFirst( ( Node a ) => ( a == child ) );
    assert( found !is null );

    // 
    found = root.findFirst( ( Node a ) => ( a == outsider ) );
    assert( found is null );

    // 
    assert( root.findFirst( child ) !is null );
    assert( root.findFirst( outsider ) is null );

    //
    auto a = new Node;
    auto b = new Node;
    auto c = new Node;
    auto d = new Node;
    auto e = new Node;

    //     a
    //   / | \
    //  b  c   d
    //  |
    //  e
    a.appendChild( b );
    a.appendChild( c );
    a.appendChild( d );
    b.appendChild( e );

    //
    assert( b.nextSibling is c );
    assert( c.nextSibling is d );

    //
    assert( a.findFirst( a ) == a );
    assert( a.findFirst( b ) == b );
    assert( a.findFirst( c ) == c );
    assert( a.findFirst( d ) == d );
    assert( a.findFirst( e ) == e );
    assert( a.findFirst( ( Node node ) => ( node == e ) ) == e );
    assert( a.findFirst( ( Node node ) => ( node == d ) ) == d );
    assert( a.findFirst( ( Node node ) => ( node == outsider ) ) is null );

    //
    Node[] nodes;
    a.each( ( Node node ) => ( nodes ~= node ) );
    assert( nodes == [ a, b, e, c, d ] );

    //
    Node[] childNode;
    a.eachChild( ( Node node ) => ( childNode ~= node ) );
    assert( childNode == [ b, e, c, d ] );

    //
    Node[] plainChildNode;
    a.eachChild!( a.plainChildIterator )( ( Node node ) => ( plainChildNode ~= node ) );
    assert( plainChildNode == [ b, c, d ] );

    //
    Node[] parentNodes;
    a.eachParent( ( Node node ) => ( parentNodes ~= node ) );
    assert( parentNodes.length == 0 );

    e.eachParent( ( Node node ) => ( parentNodes ~= node ) );
    assert( parentNodes == [ b, a ] );
}


