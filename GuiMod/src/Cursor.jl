mutable struct Cursor
    pos::Int
    delta::Int
    leftBorder::Int
    rightBorder::Int

    function Cursor(pos::Int, delta)
        new(pos, delta, pos-delta, pos+delta)
    end
end

function update_cursor!(cursor::Cursor)
    cursor.leftBorder = cursor.pos - cursor.delta
    cursor.rightBorder = cursor.pos + cursor.delta
end