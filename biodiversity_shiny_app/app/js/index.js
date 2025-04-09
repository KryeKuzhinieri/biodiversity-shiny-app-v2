export function removeSplash() {
  setTimeout(function() {
    $('#splash_screen').fadeOut(300, function() { $(this).hide(); });
  }, 5000);
};


export function showSplash() {
  $('#splash_screen').fadeOut(100, function() { $(this).show(); });
}
