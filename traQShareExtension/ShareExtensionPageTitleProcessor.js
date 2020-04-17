
var ShareExtensionPageTitleProcessor = function() {};

ShareExtensionPageTitleProcessor.prototype = {
run: function(arguments) {
    arguments.completionFunction({"title": document.title, "url": location.href});
}
};

// The JavaScript file must contain a global object named "ExtensionPreprocessingJS".
var ExtensionPreprocessingJS = new ShareExtensionPageTitleProcessor;
