GLB = undefined

# suppress right mouse button
document.addEventListener(
    'contextmenu'
    (e) -> e.preventDefault()
    false)

window.onresize = (event) ->
    GLB.width  = window.innerWidth
    GLB.height = window.innerHeight

    sWidth = GLB.width.toString()
    sHeight = GLB.height.toString()


    for layer in GLB.layers
        layer.resize(sWidth, sHeight)

    GLB.baseLayer.resize(sWidth, sHeight)

    GLB.grid.resizeGrid()
    GLB.drawing.resize()

    return


run = () ->
    GLB = new Linker()

    GLB.div_svg = document.getElementById( 'svg-layers' )
    
    GLB.drawing = new Drawing( 'drawing-layer' )
    GLB.grid    = new Grid( 'background-layer' )

    GLB.baseLayer = new LineLayer('white', 'base')
    GLB.setLayerFront(GLB.baseLayer)
    
    GLB.setupNewLayer()
    GLB.layers[0].canCreate = false
    GLB.layers[0].addArrow(0, 1)
    
    GLB.drSvg               = GLB.baseLayer.snap.g()

    return

####################################################################################################################################################

####################################################################################################################################################

class Linker
    constructor : ->
        @div_svg     =  0
        @strokeAlpha = 0.4
        @width       = window.innerWidth
        @height      = window.innerHeight

        @layers      = []
        @baseLayer   = 0
        @layerFront  = 0
        
        @canvas      = 0
        @deepness    = 4
        @data        = []
        @drSvg       = 0
        @dynamic     = true
        @drawLine    = 0

        @playing     = false

        @setupDialog()

    updateData : ->
        @data = (layerNow.getData() for layerNow in @layers)
        return

    setWidthHeight : (object) ->
        object.setAttribute( 'width' , @width.toString() )
        object.setAttribute( 'height', @height.toString() )

    renewDialogData : ->
        $('#layerColor').spectrum('set', @layerFront.color)

    drawDynamic : ->
        if @dynamic
            @drawing.stopDrawing()
            @drawing.clearCanvas()
            @drawing.continueDrawing()

        return

    setupDialog : ->
        self = this

        $( "#dialog" ).dialog(
            closeOnEscape : false
            open          : (event, ui) ->
                $(".ui-dialog-titlebar-close", ui.dialog || ui).hide()
        )

        $('#but-base').  button().click( -> self.setLayerFront( self.baseLayer ) )
        $('#but0').      button().click( -> self.setLayerFront self.layers[0] )
        $('#but1').      button().click( -> self.setLayerFront self.layers[1] )
        $('#add-layers').button().click( -> self.setupNewLayer())


        changeDeepValue = (value) ->
            self.deepness = value
            self.drawDynamic()
            return

        $('#deep-spinner')
        .spinner(
            step : 1
            numberFormat : "n"
        )
        .spinner('value', self.deepness)
        .spinner(
            min : 0
            spin : (evt, ui) ->
                changeDeepValue(ui.value)

            change : (evt, ui) ->
                changeDeepValue($('#deep-spinner').spinner('value'))
        )


        $('#rel-width').button().click( -> 
            self.drawing.relWidth = !self.drawing.relWidth
            return
        )

       

        $('#grid-type').buttonset()
        $('#putCartesianGrid').button().click( -> self.grid.changeType( 'cartesian' ) )
        $('#putPolarGrid').    button().click( -> self.grid.changeType( 'polar' ) )
        $('#removeGrid').      button().click( -> self.grid.changeType( 'none' ) )

        $('#dynamic-drawing').button().click( ->
            self.dynamic = not self.dynamic 
            return
        )


        $('#save-png').button().click( -> window.open( self.drawing.canvas.toDataURL("image/png") ) )

        updateAllColors = (layer, color) ->

            console.log(color);
            if (color is null)
                layer.alpha = 0
                return

            color = color.toString()

            layNum = self.layers.indexOf(layer)
            layer.changeColor(color)
            layer.alpha = 1

            for lay in self.layers
                lay.changeLineColors(layNum, color)

            GLB.baseLayer.changeLineColors(layNum, color)

            return

            
        $( "#play" ).button({
            text : false
            icons: {
                primary: "ui-icon-play"
            }
        })
        .click( ->
            self.drawing.pauseOrContinueDrawing()
        );

        $( "#stop" ).button({
            text : false
            icons: {
                primary: "ui-icon-stop"
            }
        })
        .click( ->
            self.drawing.stopDrawing()
        );

        $('#clear-canvas').button().click( -> self.drawing.clearCanvas() )
       

        $('#layerColor').spectrum({
            allowEmpty : true
            clickoutFiresChange: true
            showButtons: false
            flat       : true
            
            showInput  : true

            move  : (color) -> updateAllColors(self.layerFront, color)
                
            hide: (color) -> updateAllColors(self.layerFront, color)
            
        })

        $('#min-dist').slider({
            min : 1
            max : 20
            value : 4
            slide : (evt, ui) -> self.drawing.minDist = ui.value
        })

        $('#alphaSlider').slider(
            value : self.strokeAlpha * 100
            max   : 100
            min   : 0
            slide : (evt, ui) -> self.strokeAlpha = ui.value / 100
        )

        return

    # moves the svg layer to the front
    setLayerFront : (lnow) ->
        @layerFront.makeInvisible() if @layerFront
        @layerFront = lnow
        @layerFront.makeVisible()

        @renewDialogData();

        # Append the front layer again so that it will be in front 
        # and would catch lick events
        @div_svg.appendChild( lnow.snap.node )

    setupNewLayer : ->
        # Variables for fast access
        number      = (@layers.length).toString()
        id_name     = 'but' + number

        # Create new button for the layer
        new_button  = document.createElement('button')
        new_button.setAttribute('id', id_name)
        new_button.setAttribute('class', 'line-button')
        new_button.innerHTML = 'Layer ' + number 

        # Put the button in the specified div
        buttons_div = document.getElementById('buttons-div')
        buttons_div.appendChild(new_button)

        # On click, should open the specified layer
        self = this
        $('#'+id_name).button().click(
            () -> self.setLayerFront(self.layers[number]))

        # Create new layer, put it in array
        # and make it the front Layer
        newLayer    = new LineLayer(Utils.colors[@layers.length])
        @layers.push(newLayer)
        @setLayerFront(newLayer)

####################################################################################################################################################

####################################################################################################################################################

class Canvas
    constructor : (div) ->
        @canvas  = document.createElement('canvas')
        @context = @canvas.getContext( '2d' )
        @canvas.setAttribute( 'class', 'absolute-pos' )
        GLB.setWidthHeight( @canvas )
        $( '#' + div ).append( @canvas )

    clearCanvas : ->
        ctx = @canvas.getContext( '2d' )
        ctx.clearRect(0, 0, GLB.width, GLB.height)

    resize : () -> GLB.setWidthHeight( @canvas )
         

####################################################################################################################################################

####################################################################################################################################################

class Drawing extends Canvas

    constructor : (div) ->
        super(div)
        @minDist         = 4
        @relWidth        = true
        @queue           = []
        @timer           = 0
        @drawPerInterval = 300

        

        # For optimization reasons, these variables are declared here
        # and reused in the drawRecurLineCanvas function
        @_ref   = 0
        @_pNow  = []
        @_SvecX 
        @_SvecY 
        @_FvecX 
        @_FvecY 
        @_type  
        @_lev    
        @_x1
        @_y1
        @_x2
        @_y2
        @_i
        @_flip
        @_matrix = new Matrix()
        @_ang
        @_rad
        @_randAng
        @_randRad
        @_temp
        @_width
        @_outsideS
        @_outsideF

        return

    drawCanvas : (x1, y1, x2, y2, type) ->
        @_width = 1

        if @relWidth is true
            @_width = Math.sqrt( (x2-x1)**2 + (y2-y1)**2 ) / 10
            @_width = 1 if @_width < 1
        
        @context.lineCap     ='round'
        @context.lineWidth   = @_width
        @context.strokeStyle = GLB.layers[type].color
        @context.globalAlpha = GLB.strokeAlpha * GLB.layers[type].alpha

        @context.beginPath()
        @context.moveTo(x1 | 0, y1 | 0)
        @context.lineTo(x2 | 0, y2 | 0)
        @context.stroke()

        return

    # Calls the @drawRecurLineCanvas() function the required number of times
    # and also updates the data about the @queue.length
    drawOnInterval : =>
        i = Math.min(@drawPerInterval, @queue.length)
        while 0 < i-- 
            @drawRecurLineCanvas()

        $('#queueLength').html(@queue.length)

        if @queue.length is 0
            @pauseDrawing()
        return

    Drawing::drawLine = Drawing::drawCanvas

    startDrawing : =>
        GLB.updateData()
        b = GLB.baseLayer.getData()

        # For every edge in the base layer, draw recursively
        for i in [0...b.list.length] by 1
            f = b.list[i].from
            t = b.list[i].to
            
            GLB.drawing.queue.push([
                b.raw[f].x
                b.raw[f].y
                b.raw[t].x
                b.raw[t].y
                b.graph[f][t]
                GLB.deepness
                1 # flipped
            ])

        
        if @timer is 0
            @timer = setInterval(@drawOnInterval, 1)

        return

    pauseOrContinueDrawing : ->
        if @timer is 0
            @continueDrawing()
        else
            @pauseDrawing()

    continueDrawing : =>
        $('#play').button( 'option', {
            icons :
                primary: "ui-icon-pause"
        })


        if @queue.length is 0
            @startDrawing()

        if @timer is 0
            @timer = setInterval(@drawOnInterval, 1)

    pauseDrawing : =>
        $('#play').button( 'option', {
            icons :
                primary: "ui-icon-play"
        })


        clearInterval(@timer)
        @timer = 0

    stopDrawing : =>
        $('#play').button( 'option', {
            icons :
                primary: "ui-icon-play"
        })

        $('#queueLength').html(0)

        @pauseDrawing()
        @queue = []

    drawRecurLineCanvas :  =>
        if @queue.length < 1 
            @stopDrawing()
            return

        # Get data from the queue and
        # store it in predefined variables
        @_ref = @queue.shift()
        @_SvecX = @_ref[0]
        @_SvecY = @_ref[1]
        @_FvecX = @_ref[2]
        @_FvecY = @_ref[3]
        @_type  = @_ref[4].colorNum
        @_lev   = @_ref[5]
        @_flip  = @_ref[6]

        # extend the bounds so as to be sure that it's not prematurely
        @_outsideS = (@_SvecX < -GLB.width or @_SvecX > GLB.width*2) or (@_SvecY < -GLB.height or @_SvecY > GLB.height*2)
        @_outsideF = (@_FvecX < -GLB.width or @_FvecX > GLB.width*2) or (@_FvecY < -GLB.height or @_FvecY > GLB.height*2)

        # Decide to draw the line or to 
        # go deeper
        if  @_lev  is 0 or 
            @_type is 0 or # the 0 @_type is set to be a simple line so it can be optimized
                ((@_SvecX - @_FvecX)**2 + (@_SvecY - @_FvecY)**2) < (@minDist * @minDist) or # smaller than 1 pixel
                (@_outsideS and @_outsideF) # both points are outside
        
            @drawLine(@_SvecX, @_SvecY, @_FvecX, @_FvecY, @_type);

        else if @_lev > 0            
            @_list      = GLB.data[@_type].list
            @_points    = GLB.data[@_type].points
            @_graph     = GLB.data[@_type].graph
            @_variation = GLB.data[@_type].variation

            @_pNow = []

            # Distance and angle between the start and end point
            @_rad = Utils.dist2points(@_SvecX, @_SvecY, @_FvecX, @_FvecY)
            @_ang = Math.atan2(@_FvecY - @_SvecY, @_FvecX - @_SvecX)

            # Create the matrix
            @_matrix.clear()
                    .manual([1, 0, 0,   0, @_flip, 0,   0, 0, 1])
                    .rotate(@_ang)
                    .scale(@_rad, @_rad)
                    .translate(@_SvecX, @_SvecY)


            # Apply the matrix to the points
            @_i = 0
            while @_i < @_points.length
                @_temp = @_matrix.apply([@_points[@_i][0], @_points[@_i][1]])
                
                # Random vector 
                if @_variation[@_i] > 0
                    @_randAng = Math.random() * 2 * Math.PI
                    @_randRad = Math.random() * @_rad * @_variation[@_i]
                    @_temp[0] += @_randRad * Math.cos(@_randAng)
                    @_temp[1] += @_randRad * Math.sin(@_randAng)

                @_pNow.push(@_temp)

                @_i += 1


            # The arrows
            @_i = @_list.length
            while @_i > 0
                @_i -= 1

                @_x1 = @_pNow[ @_list[@_i].from ][0]
                @_y1 = @_pNow[ @_list[@_i].from ][1]
                @_x2 = @_pNow[ @_list[@_i].to ][0]
                @_y2 = @_pNow[ @_list[@_i].to ][1]

                # Control the length of the segment 
                # and act accordingly
                if ((@_x1-@_x2)**2 + (@_y1-@_y2)**2) < 
                        (@minDist * @minDist)
                    @drawLine(@_x1, @_y1, @_x2, @_y2, @_type)
                    continue

                @queue.push([
                    @_pNow[ @_list[@_i].from ][0], # start x
                    @_pNow[ @_list[@_i].from ][1], # start y
                    @_pNow[ @_list[@_i].to ][0],   # end x
                    @_pNow[ @_list[@_i].to ][1],   # end y
                    @_graph[ @_list[@_i].from ][ @_list[@_i].to ], # type
                    @_lev-1,                        # recursion level
                    @_flip * @_graph[ @_list[@_i].from ][ @_list[@_i].to ].flipped
                ])
            

        return

####################################################################################################################################################

####################################################################################################################################################

class Grid extends Canvas

    constructor : (div) ->
        super(div)
        @type = 'cartesian'
        @step = 30

        @polar5step = @step * 5
        @polar1step = @step * 20

        @polarX = GLB.width / 2
        @polarY = GLB.height / 2

        @putGrid()

    @removeGrid = ->

    changeType : (newType) ->
        @type = newType
            
        box = GLB.layerFront.lastCircle.getBBox()    
        @polarX = box.cx
        @polarY = box.cy

        @putGrid()

    resizeGrid : ->
        @resize()
        @putGrid()


    putGrid : ->
        @clearCanvas()
        switch @type
            when 'cartesian'
                @putCartesianGrid()
            when 'polar'
                @putPolarGrid()

    putCartesianGrid : () ->        
        
        ctx = @canvas.getContext('2d')
        length = Math.max(GLB.width, GLB.height)

        ctx.strokeStyle = 'gray'
        

        for i in [0...length] by @step
            if (i / @step) % 15 is 0
                ctx.lineWidth = 1.7
            else if (i / @step) % 5 is 0 
                ctx.lineWidth = 1
            else
                ctx.lineWidth = 0.5

            ctx.beginPath()
            ctx.moveTo(0, i)
            ctx.lineTo(length, i)

            ctx.moveTo(i, 0)
            ctx.lineTo(i, length)
            ctx.stroke()  
        return

    putPolarGrid : ->
        x = @polarX
        y = @polarY
        ctx = @canvas.getContext( '2d' )


        putLine = (ang, dist, len) ->
            vSt = new Vector(x + dist, y)
            vEn = new Vector(x + dist + len, y)
            rad = ang * Math.PI / 180

            vEn.rotate(rad, x, y)
            vSt.rotate(rad, x, y)

            ctx.beginPath()
            ctx.moveTo(vSt.x, vSt.y)
            ctx.lineTo(vEn.x, vEn.y)
            ctx.stroke()        

        ctx.strokeStyle = 'gray'

        # The circles
        for i in [0...GLB.width] by @step
            if (i / @step) % 10 is 0
                ctx.lineWidth = 1.8
            else if (i / @step) % 5 is 0
                ctx.lineWidth = 1
            else
                ctx.lineWidth = 0.5

            ctx.beginPath()
            ctx.arc(@polarX, @polarY, i, 0, 2 * Math.PI)
            ctx.stroke()

        length = Math.max(GLB.width, GLB.height)

        # Base points of the lines
        ctx.lineWidth = 1.7
        for i in [0..270] by 90
            putLine( 0 + i, 0, length) 
            putLine(30 + i, 0, length) 
            putLine(45 + i, 0, length) 
            putLine(60 + i, 0, length) 
        

        # Every 5 degrees
        ctx.lineWidth = 1
        for i in [0...360] by 5
            putLine(i, @polar5step, length)

        # Every 1 degree
        ctx.lineWidth = 0.5
        for i in [0...360] by 1
            putLine(i, @polar1step, length)


    gridSnap : (x, y) ->
        switch @type
            when 'cartesian'
                @gridSnapCartesian(x, y)
            when 'polar'
                @gridSnapPolar(x, y) 
            else
                new Vector(x, y)
                
    gridSnapCartesian : (x, y) ->
        px = x - ( x % @step )
        py = y - ( y % @step )

        px = Utils.closest(x, px, px + @step)
        py = Utils.closest(y, py, py + @step)

        new Vector(px, py)    

    gridSnapPolar : (nx, ny) ->
        px  = @polarX
        py  = @polarY

        vec = new Vector(nx - px, ny - py)

        # Radius
        vec.rad -= vec.rad % @step

        # Angle
        ang = vec.ang * 180 / Math.PI
         
        ang += 360 if ang < 0  
        ang -= 360 if ang > 360

        if vec.rad < @polar5step

            for i in [0...Utils.trigPoints.length] by 1
                if Utils.trigPoints[i] > ang
                    ang = Utils.closest(ang, Utils.trigPoints[i-1], Utils.trigPoints[i])
                    break


            vec.ang = ang * Math.PI / 180;

        else if vec.rad < @polar1step
            left = ang - (ang % 5)
            vec.ang = Utils.closest(ang, left, left + 5) * Math.PI / 180
        else
            left = ang - (ang % 1)
            vec.ang = Utils.closest(ang, left, left + 1) * Math.PI / 180

        vec.x += px
        vec.y += py

        return vec

####################################################################################################################################################

####################################################################################################################################################

class Circle

    constructor : (layer, x, y, innerCol, outterCol) ->
        setupGroup = () =>
            self = this

            layer.snap.g(@outterCirc, @innerCirc)
                .drag(@_mouseMove, @_mouseDown, @_mouseEnd, this, this, this)
                .mouseup( () ->
                    if layer.canCreate
                        if layer._crLine.now is 'dragging'
                            indStart = layer.circles.indexOf(layer._crLine.start)
                            indEnd   = layer.circles.indexOf(self)
                            layer.addArrow(indStart, indEnd)
                            layer._crLine.arrow.attr( points: '' )
                )

        @dragType    = 'none'
        @canBeRandom = true
        @layer       = layer
        
        @outterCirc  = layer.snap.circle(x, y, 25).attr( 'fill' : outterCol )
        @innerCirc   = layer.snap.circle(x, y, 15).attr( 'fill' : innerCol  )
        @varCirc     = layer.snap.circle(x, y,  0).attr( 'fill' : 'blue'    )

        this.makeVisible()

        @group = setupGroup()


    _mouseDown  : (x, y, evt) ->
        nowType = Utils.buttonType( evt )

        if evt.ctrlKey is false
            switch nowType
                when 'left' 
                    @dragType = 'left';

                when 'right'
                    if @layer.canCreate
                        @dragType           = 'right'
                        
                        box                 = @group.getBBox()
                        
                        @layer._crLine.now   = 'dragging'
                        @layer._crLine.stX   = box.cx
                        @layer._crLine.stY   = box.cy
                        @layer._crLine.start = this

                when 'middle'
                    if @layer.canCreate
                        @layer.removeCircle(this)

        else
            switch nowType
                when 'left'
                    if @canBeRandom
                        @dragType = 'random'
                        @varCirc.attr( r : Utils.dist2points(@getCx(), @getCy(), x, y) )

                when 'middle'
                    @varCirc.attr( r : 0 )

        return
   
    _mouseMove : (dx, dy, nx, ny, evt) ->
        if @dragType is 'left'
            vec = GLB.grid.gridSnap(nx, ny)
            @moveTo(vec.x, vec.y)

            @layer.updateArrows()
        if @dragType is 'right' and @layer.canCreate
            
            a = Utils.getArrow(@layer._crLine.stX, @layer._crLine.stY, nx, ny, 15)

            Utils.setpoly(@layer._crLine.arrow, a)     

        else if @dragType is 'random'
            @varCirc.attr( r : Utils.dist2points(@getCx(), @getCy(), nx, ny) )
        
        GLB.drawDynamic()

        return               
        
    _mouseEnd : (evt) ->
        @layer.lastCircle = this
        if @dragType == 'left'
            # nothing happens
        else if @dragType == 'right' and
                @layer.canCreate
            @layer._crLine.now = ''
            @layer._crLine.arrow.attr( points: '' )

        @dragType = 'none'
        return

  
    moveTo : (nx, ny) ->
        @innerCirc.attr(
            cx : nx
            cy : ny
        )
        @outterCirc.attr(
            cx : nx
            cy : ny
        )
        @varCirc.attr(
            cx : nx
            cy : ny
            )
        return 

    changeInnerColor : (color) -> @innerCirc.attr('fill' : color)

    makeInvisible : () ->
        @innerCirc .attr( 'fill-opacity' : 0)
        @outterCirc.attr( 'fill-opacity' : 0)
        @varCirc   .attr( 'fill-opacity' : 0)
        return

    makeVisible : () ->
        @innerCirc .attr( 'fill-opacity' : 0.5)
        @outterCirc.attr( 'fill-opacity' : 0.5)
        @varCirc   .attr( 'fill-opacity' : 0.3)
        return
    
    getBBox : () -> @group.getBBox()

    remove : () ->
        @group.remove()
        @varCirc.remove()
        return

    getCx : () -> parseFloat( @innerCirc.attr( 'cx' ) )

    getCy : () -> parseFloat( @innerCirc.attr( 'cy' ) )
        

    removeInteractivity : ->
        @group.undrag()
        return

####################################################################################################################################################

####################################################################################################################################################

class Arrow
    constructor : (layer, colNum, cStart, cEnd) ->
        setupArrowPolyline = =>
            arrow = this

            layer.snap.polyline()
                .attr(
                    'fill'        : GLB.layers[arrow.colorNum].color
                    'fill-opacity': 0.8
                )
                .mousedown((evt) ->
                    if layer.canCreate 
                        nowType = Utils.buttonType(evt)

                        if evt.ctrlKey is true
                            # didn't implemented it yet :(
                        else if evt.altKey is true
                            arrow.flipped *= -1
                            arrow.update()
                        else
                            if nowType is 'left'
                                arrow.colorNum = (arrow.colorNum + 1) % GLB.layers.length
                                this.attr( fill: GLB.layers[arrow.colorNum].color )

                            else if nowType is 'middle'
                                layer.removeArrow(arrow)

                    GLB.drawDynamic()
                )

        @circStart = cStart 
        @circEnd   = cEnd

        @colorNum = colNum
        @flipped  = 1

        @poly = setupArrowPolyline()
        @update()

    # Updates position and sty
    update : () ->
        box1 = @circStart.getBBox()
        box2 = @circEnd.getBBox()

        if @flipped is 1 
            Utils.setpoly(@poly, Utils.getArrow(box1.cx, box1.cy, box2.cx, box2.cy, 15, 0))
        else
        if @flipped is -1
            Utils.setpoly(@poly, Utils.getArrow(box1.cx, box1.cy, box2.cx, box2.cy, 25, -1))
        
        return

    makeInvisible : ()       -> @poly.attr( 'fill-opacity' : 0 )
    
    updateColor   : (newcol) -> @poly.attr('fill', newcol)
    
    remove        : ()       -> @poly.remove()

    makeVisible   : ()       -> @poly.attr( 'fill-opacity' : 0.8 )

####################################################################################################################################################

####################################################################################################################################################

class Background
    constructor : (layer) ->        
        @rect = layer.snap.rect(0, 0, GLB.width, GLB.height)
                    .attr( 'fill' : layer.color )
                    # .drag(backMove, backStart, backEnd)
                    .mouseup((evt) ->
                        if layer.canCreate
                            if Utils.buttonType(evt) == 'right' and
                                    layer._crLine.now != 'dragging' 
                                nx = evt.clientX
                                ny = evt.clientY

                                layer.addCircle(nx, ny, 'gray')       
                    )

        @makeVisible()

        return

    makeInvisible : () -> 
        @rect.attr('fill-opacity' : 0)
        return this

    makeVisible : () ->
        @rect.attr('fill-opacity' : 0.2)
        return this

    resize : ( width, height ) ->
        @rect.attr(
            'width'  : width
            'height' : height
        )
        return this

    changeColor : ( color ) ->
        @rect.attr( 'fill' : color )
        return this

####################################################################################################################################################

####################################################################################################################################################

class LineLayer
    constructor : (col, base) ->  

        createInitialCircles = () =>
            if @layerType == 'base'
                @addCircle(100, 100, 'gray')
            else
                @addCircle(100, 100, 'green')
                @addCircle(200, 100, 'red')
                @circles[0].canBeRandom = 
                    @circles[1].canBeRandom = false
            return

        ## Initialization ##
        @layerType  = base
        @color      = col
        @alpha      = 1 # should be only 1 or 0, no gray values 
        @canCreate  = true
        
        @snap       = Snap(GLB.width, GLB.height).attr( class: 'absolute-pos' )
        
        # Array of the arrows
        @arrows     = []
        # Array of the circles
        @circles    = []
        @background = new Background(this)
        
        # 2D array that represents the graph in a table form
        @graph      = []    

        # The arrow used temporary while creating other arrows
        @_crLine = 
            # the svg element
            arrow: @snap.polyline()
            # the circle at the start
            start: 0
            # coordinates of start
            stX: 0
            stY: 0

        # In order to put the circles above the lines
        @SVGgroups =
            SVGvisuals    : @snap.g()
            SVGbackground : @snap.g()
            SVGarrows     : @snap.g()
            SVGcircles    : @snap.g()

        @SVGgroups.SVGvisuals.add(@_crLine.arrow)
        # @SVGgroups.SVGbackground.add(@background.rect)
        
        createInitialCircles()

        @lastCircle = @circles[0]


    resize : (width, height) ->
        sWidth  = width.toString()   
        sHeight = height.toString()

        @snap.node.setAttribute( 'width' , sWidth  )
        @snap.node.setAttribute( 'height', sHeight )

        @background.resize(width, height)

        @SVGgroups.SVGbackground.attr(
            'width'  : sWidth  
            'height' : sHeight
        )

    # Make disks and arrows invisible
    makeInvisible : ->
        @background.makeInvisible()
        circle.makeInvisible() for circle in @circles
        arrow.makeInvisible()  for arrow  in @arrows
        return 

    # Make disks and arrows visible 
    makeVisible : ->
        @background.makeVisible()
        circle.makeVisible() for circle in @circles
        arrow.makeVisible()  for arrow  in @arrows
        return

    addArrow    : (pos1, pos2)  ->
        if @graph[pos1][pos2] is 0
            p = new Arrow(this, 0, @circles[pos1], @circles[pos2])

            @SVGgroups.SVGarrows.add( p.poly )
            @graph[pos1][pos2] = p

            @arrows.push(p)

        return

    # If gets only one argument that argument is considered to be the line
    # If gets 2 arguments considers them to be the row and column
    removeArrow : (line, col) ->
        if arguments.length is 1
            # Find the line in the graph
            for i in [0...@graph.length] by 1
                j = @graph[i].indexOf(line)
                break if j > -1
        else
            i = line
            j = col
        

        @graph[i][j].remove()
        @graph[i][j] = 0
        return

    addCircle   : (x, y, outterColor) ->
        ncircs = @circles.length

        @graph.push( Utils.array1D(ncircs, 0) )
        for i in [0..ncircs] by 1
            @graph[i].push(0)

        vec = GLB.grid.gridSnap(x, y)

        circle = new Circle(this, vec.x, vec.y, @color, outterColor)

        circle.canBeRandom = false if @layerType is 'base'

        @SVGgroups.SVGcircles.add( circle.group )
        @SVGgroups.SVGvisuals.add( circle.varCirc )
        @circles.push(circle)
        return
    
    removeCircle : (circ) ->
        pos = @circles.indexOf(circ);

        @removeIncidentLines(circ)

        if pos > 1 or @layerType is 'base'
            circ.remove()

            # delete row and column
            @graph.splice(pos, 1)
            for i in [0...@graph.length] by 1
                @graph[i].splice(pos, 1)

            @circles.splice(pos, 1)
        return
    
    changeColor : (color) ->
        @color = color

        @background.changeColor( color )        
        c.changeInnerColor( color ) for c in @circles
        return

    # Change the color of all the arrows of type layNum
    changeLineColors : (layNum, color) ->
        for arrow in @arrows
            if arrow.colorNum is layNum
                arrow.updateColor( color )
        return 
        
    # Remove arrows incident to a disk
    removeIncidentLines : (circle) ->
        ind = @circles.indexOf(circle)

        for i in [0...@circles.length] by 1
            @removeArrow(ind, i) if @graph[ind][i]
            @removeArrow(i, ind) if @graph[i][ind]

        return
    
    # Update all arrows
    updateArrows : () -> arrow.update() for arrow in @arrows
    
    # Return data needed for creating the fractal
    getData : () ->
        num    = @circles.length
        graph  = Utils.array2D(num, num, -1)
        points = []

        # Get the center of every circle
        for i in [0...num] by 1
            box = @circles[i].getBBox()
            points.push(new Vector(box.cx, box.cy))

        # The arrows between the points
        for i in [0...num] by 1
            for j in [0...num] by 1
                if @graph[i][j]
                    graph[i][j] = @graph[i][j].colorNum  

        # The base layer does not have start and end points
        if points.length > 1
            dist_01 = Utils.dist2points(points[0].x, points[0].y, points[1].x, points[1].y) 
        else
            dist_01 = 1


        variation = ( c.varCirc.attr('r') / dist_01 for c in @circles )
        arrowList = Utils.listFromArray(graph, (x) -> x != -1)
        
        return {
            graph     : @graph
            raw       : points
            points    : Utils.toUnitVectors(points)
            list      : arrowList
            variation : variation
        }
