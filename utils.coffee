class Matrix
    constructor : () ->
        @mat  = Utils.array1D(9, 0)
        @temp = Utils.array1D(9, 0)
        @chg  = Utils.array1D(9, 0)
        @clear()


    clear : () ->
        Utils.unitMatrix3(@mat)
        return this

    apply : (p) ->
        return [p[0] * @mat[0] + p[1] * @mat[3] + @mat[6], 
                p[0] * @mat[1] + p[1] * @mat[4] + @mat[7]]
  

    translate : (x, y) ->
        Utils.unitMatrix3(@chg)
        @chg[6] = x
        @chg[7] = y
        Utils.matrix3x3(@mat, @chg, @temp)
        Utils.copyArray(@temp, @mat, 9)
        return this
  

    rotate : (th) ->
        Utils.unitMatrix3(@chg)
        @chg[0] = Math.cos(th)
        @chg[1] = Math.sin(th)
        @chg[3] = -Math.sin(th)
        @chg[4] = Math.cos(th)
        Utils.matrix3x3(@mat, @chg, @temp)
        Utils.copyArray(@temp, @mat, 9)
        return this
  

    scale : (x, y) ->
        Utils.unitMatrix3(@chg)
        @chg[0] = x
        @chg[4] = y
        Utils.matrix3x3(@mat, @chg, @temp)
        Utils.copyArray(@temp, @mat, 9)
        return this
  

    manual : (mat) ->
        Utils.matrix3x3(@mat, mat, @temp)
        Utils.copyArray(@temp, @mat, 9)
        return this




Utils = 

    trigPoints : [0, 30, 45, 60,
                 0  +  90,  30 +  90, 45 +  90, 60 +  90,
                 0  + 180 , 30 + 180, 45 + 180, 60 + 180,
                 0  + 270 , 30 + 270, 45 + 270, 60 + 270,
                 360]

    # Changes the points of a svg polyline
    setpoly : (p, arr) ->
        p.attr( points: Utils.arrXYToStr(arr) ) 

    closest : (mid, left, right) ->
        if (Math.abs(mid - left) < Math.abs(mid - right))
            return left
        else
            return right
    

    dist2points : (x1, y1, x2, y2) ->
        Math.sqrt((x1-x2)**2 + (y1-y2)**2) 
    

    getArrow: (x1, y1, x2, y2, rad, side) ->
        a = [new Vector(0, -rad), 
             new Vector(0,  rad), 
             new Vector(x2, y2)]

        if side is 1
            a[1].y = 0; 
        else 
        if side is -1
            a[0].y = 0
        

        nv = new Vector(x2-x1, y2-y1)

        for i in [0...2] by 1
            a[i].ang += nv.ang

            a[i].x += x1
            a[i].y += y1

        return a
        

    arrXYToStr : (arr) ->
        str = '';
        for i in [0...arr.length] by 1
            str += ' ' + arr[i].x + ' ' + arr[i].y
        return str
        

    buttonType : (evt) ->
        if !evt.buttons
            switch evt.which
                when 1 then return 'left'
                when 2 then return 'middle'
                when 3 then return 'right' 
            
        else 
            switch evt.buttons
                when 1 then return 'left'
                when 4 then return 'middle'
                when 2 then return 'right'
            
        

        return 'other';
        

    colors : ['brown', 'green', 'blue',
              'red', 'yellow', 'gray', 
              'magenta', 'rose']

    toUnitVectors : (points) ->
        len = points.length
        ret = []

        # There should exist at least two points
        return if len < 2

        # Vector from start point to end point
        ang = Math.atan2( points[1].y - points[0].y, points[1].x - points[0].x )
        rad = @dist2points( points[0].x, points[0].y, points[1].x, points[1].y )

        mat = (new Matrix())
           .translate( -points[0].x, -points[0].y )
           .rotate( -ang )
           .scale( 1/rad, 1/rad )

        for i in [0...len] by 1
            ret.push(
                mat.apply([points[i].x, points[i].y])
            )
        

        return ret   
    
    # Multiplies the matrix m and t and stores the result in ret
    # the matrix should be 3x3
    matrix3x3 : (m, t, ret) ->
        ret[0] = m[0]*t[0] + m[1]*t[3] + m[2] * t[6]; 
        ret[1] = m[0]*t[1] + m[1]*t[4] + m[2] * t[7]; 
        ret[2] = m[0]*t[2] + m[1]*t[5] + m[2] * t[8];

        ret[3] = m[3]*t[0] + m[4]*t[3] + m[5] * t[6]; 
        ret[4] = m[3]*t[1] + m[4]*t[4] + m[5] * t[7]; 
        ret[5] = m[3]*t[2] + m[4]*t[5] + m[5] * t[8];

        ret[6] = m[6]*t[0] + m[7]*t[3] + m[8] * t[6]; 
        ret[7] = m[6]*t[1] + m[7]*t[4] + m[8] * t[7]; 
        ret[8] = m[6]*t[2] + m[7]*t[5] + m[8] * t[8];


    array2D : (rows, cols, init) ->
        t = new Array(rows)
        for i in [0...rows] by 1
            t[i] = new Array(cols)

            for j in [0...cols] by 1
                t[i][j] = init
        
        return t
        

    array1D : (length, init) ->
        t = new Array(length);
        for i in [0...length] by 1
            t[i] = init
        return t
    

    copyArray : (from, to, length) ->
        while --length >= 0
            to[length] = from[length]
        return

    unitMatrix3 : (mat) ->
        mat[0] = 1;
        mat[1] = 0;
        mat[2] = 0;

        mat[3] = 0;
        mat[4] = 1;
        mat[5] = 0; 
        
        mat[6] = 0;
        mat[7] = 0;
        mat[8] = 1;

    listFromArray : (graph, func) ->
        list = [];
        for i in [0...graph.length] by 1
            for j in [0...graph[i].length] by 1
                if func(graph[i][j])
                    list.push(new NDirec(i, j))
        return list
    
    random1Vec : () ->
        v = new Vector()
        v.ang = Math.random() * Math.PI * 2
        v.rad = Math.random()
        return v

class Point 
    constructor : (@x, @y) ->


class Vector
    
    constructor : (x, y) ->
        @orthX     
        @orthY     
        @polarRad  
        @polarAng  

        @setOrtho(x, y)

        Object.defineProperty(this, 'x', {
            get : () -> @orthX

            set : (val) ->
                @orthX = val
                @recalcPolar()
                return
        })


        Object.defineProperty(this, 'y', {
            get : () -> @orthY

            set : (val) ->
                @orthY = val
                @recalcPolar()
                return
        })

        Object.defineProperty(this, 'rad', {
            get : () -> @polarRad

            set : (val) ->
                @polarRad = val
                @recalcOrtho()
                return
        })

        Object.defineProperty(this, 'ang', {
            get : () -> @polarAng
            
            set : (val) ->
                @polarAng = val
                @recalcOrtho()
                return
        })

    show : () ->
        console.log(@orthX + ' ' + @orthY)
        return
    

    getSimpleOrtho : () ->
        return {x: @orthX, y: @orthY}
    

    getSimplePolar : () ->
        return {rad: @polarRad, ang: @polarAng}
    

    recalcOrtho : () ->
        @orthX = Math.cos(@polarAng) * @polarRad
        @orthY = Math.sin(@polarAng) * @polarRad
    

    recalcPolar : () ->
        @polarRad = Math.sqrt(@orthX*@orthX + @orthY*@orthY)
        @polarAng = Math.atan2(@orthY, @orthX)
    
    rotate : (nang, nx, ny) ->
        oldx = @orthX
        oldy = @orthY

        @orthX = nx + (oldx - nx) * Math.cos(nang) - (oldy - ny) * Math.sin(nang)
        @orthY = ny + (oldx - nx) * Math.sin(nang) + (oldy - ny) * Math.cos(nang)

        @recalcPolar()
        return

    # SETTERS
    setOrtho : (x, y) ->
        if arguments.length is 1
            @orthX = x.x
            @orthY = x.y
        else
            @orthX = x || 0
            @orthY = y || 0
        

        @recalcPolar()
        return
    

    setPolar : (rad, ang) ->
        @polarRad = rad || 0
        @polarAng = ang || 0

        @recalcOrtho()

class NDirec
    constructor : (@from, @to) ->


array2D = (rows, cols) ->
    t = new Array(rows);
    for i in [0...rows] by 1
        t[i] = new Array(cols)
        for j in [0...cols] by 1
            t[i][j] = 0;
    
    return t


