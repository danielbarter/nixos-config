button_container = document.getElementById("button_container");

global_state = { "hit_count" : -1, "state" : "undefined" };


function get_state () {
    fetch("http://rupert.meow:10001/api/status");
};

