import { mount } from "svelte";
import Standings from "../standings/Standings.svelte";

document.addEventListener("turbolinks:load", function () {
  const anchor = document.getElementById("standings_anchor");
  if (anchor && anchor.childNodes.length == 0) {
    mount(Standings, {
      target: anchor,
      props: {
        tournamentId:
          Number(anchor.getAttribute("data-tournament") ?? "") || -1,
      },
    });
  }
});
