import { mount } from "svelte";
import TournamentCreation from "../tournaments/TournamentCreation.svelte";

document.addEventListener("turbolinks:load", function () {
  const anchor = document.getElementById("tournament_creation_anchor");
  if (anchor && anchor.childNodes.length === 0) {
    mount(TournamentCreation, {
      target: anchor,
    });
  }
});
