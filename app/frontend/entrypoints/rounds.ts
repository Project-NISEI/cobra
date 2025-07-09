import { mount } from "svelte";
import Rounds from "../pairings/Rounds.svelte";

document.addEventListener("turbolinks:load", function () {
  const anchor = document.getElementById("rounds_anchor");
  if (anchor && anchor.childNodes.length == 0) {
    mount(Rounds, {
      target: anchor,
      props: {
        tournamentId: Number(anchor.getAttribute("data-tournament") ?? "") || -1,
      },
    });
  }
});
