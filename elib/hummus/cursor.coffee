# cursor class
module.exports = class Cursor
    # our properties
    _context: null
    _x: 0
    _y: 760 # start position
    _font: null
    _size: 11
    _color: 0x000000
    _lineSpacing: 1
    _lineHeight: 0

    # create object
    constructor: (@_context) ->
        @

    # the the font and possibly the size
    setFont: (@_font, size) ->
        @_size = size if size?
        @_computeLineHeight()
        @

    # sets the font size
    setFontSize: (@_size) ->
        @_computeLineHeight()
        @

    # sets the line spacing
    setLineSpacing: (spacing) ->
        @_lineSpacing = spacing
        @

    # sets the color
    setColor: (color) ->
        @_color = color
        @

    # write a line of text
    writeText: (text) ->
        @_writeText text, @_x, @_y

        # return
        @

    # write a line of text
    writeLine: (text) ->
        # write the text
        @writeText text

        # increment y
        @skipLine()

        # return
        @

    # write many lines
    writeLines: (lines) ->
        lines = [lines] unless Array.isArray(lines)
        for line in lines
            @writeLine line
        @

    # write text in the bounding box
    writeBox: (text, width, height, halign, valign) ->
        # compute dimension
        dimension = @_font.calculateTextDimensions text, @_size

        # compute missing properties
        width = width or dimension.width
        height = height or dimension.height

        # default position
        x = @_x
        y = @_y

        # horizontal alignment
        if halign is 'center'
            x = @_x + Math.round(width / 2) - Math.round(dimension.width / 2)
        else if halign is 'right'
            x = @_x + width - dimension.width

        # vertical alignment
        if valign is 'middle'
            y = @_y - Math.round(height / 2) + Math.round(dimension.height / 2)
        else if valign is 'bottom'
            y = @_y - height + dimension.height

        # write the text
        @_writeText text, x, y

        # return
        @

    # write object specification
    writeObject: (object) ->
        # switch by type
        if object?.type is 'image'
            @_context.drawImage object.x, object.y, object.file
        else if object?.type is 'text'
            if object.x? and object.y?
                @_writeText object.text, object.x, object.y
            else
                @writeLine object.text

        # return
        @

    # write many object specifications
    writeObjects: (objects) ->
        objects = [objects] unless Array.isArray(objects)
        for object in objects
            @writeObject object
        @

    # skip a line of text
    skipLine: (number = 1) ->
        # increment y
        @_y -= Math.round(1000 * number * (@_lineHeight + @_lineSpacing * @_lineHeight)) / 1000
        @

    # get the context
    getContext: ->
        @_context

    # get the current position
    getPosition: ->
        {
            x: @_x
            y: @_y
        }

    # get x position
    getX: ->
        @_x

    # get y position
    getY: ->
        @_y

    # set a new position
    setPosition: (x, y) ->
        @_x = x
        @_y = y
        @

    # set x
    setX: (x) ->
        @_x = x
        @

    # set y
    setY: (y) ->
        @_y = y
        @

    # move the cursor
    move: (x, y) ->
        @_x += x
        @_y += y
        @

    # move cursor X
    moveX: (x) ->
        @_x += x
        @

    # move cursor Y
    moveY: (y) ->
        @_y += y
        @

    # gets the line height
    getLineHeight: ->
        @_lineHeight

    # write the text
    _writeText: (text, x, y) ->
        @_context.writeText text, x, y,
            size: @_size
            font: @_font
            color: @_color

    # compute the line height
    _computeLineHeight: ->
        return unless @_font?
        dimension = @_font.calculateTextDimensions 'AAA', @_size
        @_lineHeight = dimension.height
