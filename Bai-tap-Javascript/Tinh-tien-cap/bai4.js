function toggleConnection() {
  var type = document.getElementById("type").value;
  var connectInput = document.getElementById("connectid");
  if (type === "business") {
    connectInput.classList.remove("hidden");
  } else {
    connectInput.classList.add("hidden");
    connectInput.value = "";
  }
}
