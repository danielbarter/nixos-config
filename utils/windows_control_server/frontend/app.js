var button_container = document.getElementById("button_container");
var counter_container = document.getElementById("counter_container");


function update(data) {
    const state = data["state"];

    // update button
    if ( state == "shutdown" ) {
	button_container.className = "shutdown";
	button_container.innerText = "start windows";
	button_container.onclick = start_windows;
    } else {
	button_container.className = "running";
	button_container.innerText = "windows running";
	button_container.onclick = windows_running;
    }

    // update counter
    counter_container.innerText = data["hit_count"].toString();
};

function tick () {
    fetch("http://rupert.meow:10001/api/status")
	.then((response) => response.json())
	.then((data) => update(data));
};


function start_windows () {
    console.log("starting windows");
    fetch("http://rupert.meow:10001/api/start")
	.then((response) => response.json())
	.then((data) => console.log("windows started"));
};

function windows_running () {
    console.log("windows already running");
};


// initial tick
tick();

// tick every 3 seconds there after
setInterval(tick, 3000);
