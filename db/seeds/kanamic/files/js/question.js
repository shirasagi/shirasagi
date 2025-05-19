$(document).ready(function() {
	$("[data-question_a]").on("click", function() {
	  const question = $(this);
	  const answer = $(this).next();
  
	  question.toggleClass("active");
	  answer.slideToggle(200);
	});
  });