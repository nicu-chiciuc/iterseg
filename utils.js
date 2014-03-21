function Vector(x, y) {
    var orthX     = 0;
    var orthY     = 0;
    var polarRad  = 0; //polar radius
    var polarAng  = 0; //polar angle

    this.getSimpleOrtho = function(){
        return {x: orthX, y: orthY};
    }

    this.getSimplePolar = function(){
        return {rad: polarRad, ang: polarAng};
    }

    this.recalcOrtho = function()
    {
        orthX = Math.sin(polarAng) * polarRad;
        orthY = Math.cos(polarAng) * polarRad;
    }

    this.recalcPolar = function()
    {
        polarRad = Math.sqrt(orthX*orthX + orthY*orthY);
        polarAng = Math.atan2(orthX, orthY);
    }

    // SETTERS
    this.setOrtho = function(x, y){
        orthX = x || 0;
        orthY = y || 0;

        this.recalcPolar();
    }

    this.setPolar = function(rad, ang){
        polarRad = rad || 0;
        polarAng = ang || 0;

        this.recalcOrtho();
    }

    Object.defineProperty(this, 'x', {
        get : function() {
            return orthX;
        },
        set : function(val) {
            orthX = val;
            this.recalcPolar();
        }
    });


    Object.defineProperty(this, 'y', {
        get : function() {
            return orthY;
        },
        set : function(val) {
            orthY = val;
            this.recalcPolar();
        }
    });

    Object.defineProperty(this, 'rad', {
        get : function() {
            return polarRad;
        },
        set : function(val) {
            polarRad = val;
            this.recalcOrtho();
        }
    });

    Object.defineProperty(this, 'ang', {
        get : function() {
            return polarAng;
        },
        set : function(val) {
            polarAng = val;
            this.recalcOrtho();
        }
    });

    // ----------- //
    this.setOrtho(x, y);
}

function NDirec(from, to){
    this.from = from;
    this.to   = to;
}

function LGraph(elems) {
    var _num     = elems < 2 ? 2 : elems; 

    this.tab2   = array2D(elems, elems);
    var _list1  = [];
    this.points = [];
    var  _vects  = [];

    var _drawQueue = [];
    var _drawLast;
    var _drawTimeout;
    var _drawContext;
    const _drawPerIteration = 700;
    const _drawSpliceAt = 1500;
    const _MIN_LINE_DIST = 2;

    var _drawTotal;

    Object.defineProperty(this, 'num', {
        get : function(){
            return _num;
        }
    });

    Object.defineProperty(this, 'list1', {
        get : function() {
            return _list1;
        }
    });

    this.set2D = function(from, to, val)
    {
        this.tab2[from][to] = val; //1 or 0
        
        this.recalcList();
    }

    this.recalcList = function(){
        _list1.length = 0;
        for (var i=0; i<_num; ++i)
        for (var j=0; j<_num; ++j)
            if (this.tab2[i][j] === 1)
                _list1.push(new NDirec(i, j));
    }

    this.deleteElm = function(elem)
    {
        this.tab2.splice(elem, 1);
        for (var i=0; i<_num-1; ++i)
            this.tab2[i].splice(elem, 1);
        _num--;

        this.recalcList();
    }

    this.addNode = function(elem){
        
        for (var i=0; i<_num; ++i)
            this.tab2[i].length++;
        this.tab2[_num] = new Array(_num+1);

        this.points[_num] = elem;

        _num++;
    }

    this.updateVectors = function(){
        _vects = [];
        //vector from start point to end point
        var dir = new Vector(this.points[1].x-this.points[0].x, this.points[1].y-this.points[0].y);

        for (var i=0; i<_num; ++i)
        {
            //vector from start point to point[i]
            var v = new Vector(this.points[i].x - this.points[0].x, this.points[i].y - this.points[0].y);
            //vector with dir as unit vector
            v.setPolar(v.rad / dir.rad, v.ang - dir.ang);
            _vects.push(v);
        }
        return _vects;   
    }
    
    this.drawRecurLineCanvas = function(context, lev) {
        _drawContext = context;
        clearTimeout(_drawTimeout);
        _drawLast = 0;
        _drawQueue.length = 0;
        _drawQueue.push(new RecurLine(this.points[0], this.points[1], lev));
        _drawRecurLine();

        _drawTotal = 1;
    }

    function _drawRecurLine() {
        var rep = Math.min(_drawPerIteration, _drawQueue.length-_drawLast);
        var Svec, Fvec, lev;

        for (var i=0; i<rep; ++i) {
            Svec = _drawQueue[_drawLast+i].Svec;
            Fvec = _drawQueue[_drawLast+i].Fvec;
            lev  = _drawQueue[_drawLast+i].lev ;


            if (lev === 0 ||
                (Math.pow(Svec.x - Fvec.x, 2) + 
                 Math.pow(Svec.y - Fvec.y, 2)) 
                    < (_MIN_LINE_DIST * _MIN_LINE_DIST) //smaller than 3 pixel
                ){
                    drawLine(Svec.x, Svec.y, Fvec.x, Fvec.y);
            }else
            if (lev > 0) {
                var dir = new Vector(Fvec.x - Svec.x, Fvec.y - Svec.y);

                var pNow = []; 

                for (var j=0; j<_num; ++j)
                {
                    var temp = new Vector(_vects[j].x, _vects[j].y);

                    temp.rad = temp.rad * dir.rad;
                    temp.ang = temp.ang + dir.ang;

                    temp.x = temp.x + Svec.x;
                    temp.y = temp.y + Svec.y;

                    pNow.push(temp);
                }

                for (var j=0; j<_list1.length; ++j)
                {
                    if (Math.pow(pNow[ _list1[j].from ].x - pNow[ _list1[j].to ].x, 2)+
                        Math.pow(pNow[ _list1[j].from ].y - pNow[ _list1[j].to ].y, 2)
                        > _MIN_LINE_DIST*_MIN_LINE_DIST)
                    _drawQueue.push(new RecurLine(pNow[ _list1[j].from ], 
                        pNow[ _list1[j].to ], lev-1));
                    else
                        drawLine(pNow[ _list1[j].from].x, pNow[ _list1[j].from].y,
                                 pNow[ _list1[j].to  ].x, pNow[ _list1[j].to  ].y);
                }
            }
        }

        _drawLast += rep;
        _drawTotal += rep;

        if (_drawLast > _drawSpliceAt) {
            _drawQueue.splice(0, _drawSpliceAt);
            _drawLast -= _drawSpliceAt;
        };
        // console.log(_drawLast + ' ' + _drawQueue.length +' ' + _drawTotal);
        if (_drawQueue.length > _drawLast)
            _drawTimeout = setTimeout(_drawRecurLine, 0);

        function drawLine(x1, y1, x2, y2){
            _drawContext.beginPath();
            _drawContext.moveTo(x1, y1);
            _drawContext.lineTo(x2, y2);
            _drawContext.stroke();
        }
    }

    //Constructor
    function RecurLine(Svec, Fvec, lev){
        this.Svec = Svec;
        this.Fvec = Fvec;
        this.lev  = lev;
    }
    
}



function LPoint(posx, posy) {
    this.x = posx;
    this.y = posy;
}

function array2D(rows, cols)
{
    var t = new Array(rows);
    for (var i=0; i<rows; ++i)
    {
        t[i] = new Array(cols);
        for (var j=0; j<cols; ++j)
            t[i][j] = 0;
    }
    return t;
}

