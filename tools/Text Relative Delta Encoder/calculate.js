function calculate() {
    var inputString = document.getElementById("inputString").value;
    var outputString = "";
    var outputString_nospace = "";
    for (var i = 0; i < inputString.length - 1; i++) {
        var asciiDifference = Math.abs(inputString.charCodeAt(i) - inputString.charCodeAt(i + 1));
        outputString += asciiDifference.toString(16).toUpperCase().padStart(2, "0") + " ";
        outputString_nospace += asciiDifference.toString(16).toUpperCase().padStart(2, "0");
    }
    document.getElementById("outputString").value = outputString.trim();
    document.getElementById("outputString_nospace").value = outputString_nospace.trim();
}
