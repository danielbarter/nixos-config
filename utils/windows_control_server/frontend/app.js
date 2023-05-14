var button_container = document.getElementById("button_container");
var counter_container = document.getElementById("counter_container");


function update(data) {
    const state = data["state"];

    // update button
    if ( state == "down" ) {
	button_container.className = "down";
	button_container.innerText = "windows down";
    } else if ( state == "starting" ) {
	button_container.className = "starting";
	button_container.innerText = "windows starting";
    } else if ( state == "up" ) {
	button_container.className = "up";
	button_container.innerText = "windows up";
    }

    // update counter
    counter_container.innerText = data["counter"];
};

function tick () {
    fetch(`${window.location.origin}:10001/api/state`)
	.then((response) => response.json())
	.then((data) => update(data));
};


function start_windows () {
    fetch(`${window.location.origin}:10001/api/start`)
	.then((response) => response.json())
	.then((data) => update(data));
};

// on click start windows
button_container.onclick = start_windows;

// initial tick
tick();

// tick every 3 seconds there after
setInterval(tick, 3000);
