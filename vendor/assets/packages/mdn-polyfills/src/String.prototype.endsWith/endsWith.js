export default function (searchStr, Position) {
    // This works much better than >= because
    // it compensates for NaN:
    if (!(Position < this.length))
        Position = this.length;
    else
        Position |= 0; // round position
    return this.substr(Position - searchStr.length,
        searchStr.length) === searchStr;
}
