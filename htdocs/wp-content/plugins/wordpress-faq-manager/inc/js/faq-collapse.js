       jQuery(document).ready(function () {
           jQuery(".faq_answer").hide();
           jQuery(".faq_question").click(function () {
               jQuery(this).next(".faq_answer").slideToggle(400);
           });
       });