function img_preload(imgNames) {
        for (var i = 0; document.images && (i < imgNames.length); i++) {
		var img = new Image();
                img.src = imgNames[i];
	}
}

function img_toggle(imgName, prefix) {
	for (var i = 0; document.images && (i < document.images.length); i++) {
		if (document.images[i].src.indexOf(imgName) >= 0) {
			document.images[i].src = prefix + imgName;
			return true;
		}
	}
        return false;
}

function img_act(imgName) {
	return img_toggle(imgName, "s");
}

function img_inact(imgName) {
	return img_toggle(imgName, "");
}