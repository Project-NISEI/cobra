import { mount } from "svelte";
import DemoTournamentCreation from "../tournaments/DemoTournamentCreation.svelte";

document.addEventListener("turbolinks:load", function () {
  const anchor = document.getElementById("demo_tournament_creation_anchor");
  if (anchor && anchor.childNodes.length === 0) {
    mount(DemoTournamentCreation, {
      target: anchor,
    });
  }
});
