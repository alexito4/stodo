
extension String {
    var ascii32: Int32 {
        Int32(Character(self).asciiValue!)
    }
}

import Darwin.ncurses

let reversed = NCURSES_BITS(1, 10)

func NCURSES_BITS(_ mask: UInt32, _ shift: UInt32) -> CInt {
    CInt(mask << (shift + UInt32(NCURSES_ATTR_SHIFT)))
}
