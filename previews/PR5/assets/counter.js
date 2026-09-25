// A minimal AFM module used by the tests and the documentation.
function render({ model, el }) {
  const button = document.createElement("button");
  button.className = "counter-button";
  const update = () => (button.textContent = `${model.get("label")}: ${model.get("count")}`);
  button.addEventListener("click", () => {
    model.set("count", model.get("count") + 1);
    model.save_changes();
  });
  model.on("change:count", update);
  update();
  el.appendChild(button);
}
export default { render };
