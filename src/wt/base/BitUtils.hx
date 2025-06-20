package wt.base;


class BitUtils {

    public static inline function setBit(bits:Int, bitNumber:Int) {
        return bits | 1 << bitNumber;
    }

    public static inline function clearBit(bits:Int, bitNumber:Int) {
        return bits & ~(1 << bitNumber);  
    }

    public static inline function setBitToValue(bits:Int, bitNumber:Int, value:Bool) {
        return if (value) setBit(bits, bitNumber);
        else clearBit(bits, bitNumber);
    }
}