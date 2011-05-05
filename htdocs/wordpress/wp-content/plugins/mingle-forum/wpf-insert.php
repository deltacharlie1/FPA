<?php
global $wpdb, $mingleforum, $user_ID, $user_level;
$error = false;
$root = dirname(dirname(dirname(dirname(__FILE__))));
require_once($root.'/wp-load.php');

	function mf_u_key()
	{
		$pref = "";
		for ($i = 0; $i < 5; $i++)
		{
		$d = rand(0,1);
		$pref .= $d ? chr(rand(97, 122)) : chr(rand(48, 57));
		}
		return $pref."-";
	}

	function MFAttachImage($temp, $name)
	{
		//GET USERS UPLOAD PATH
		$upload_dir = wp_upload_dir();
		$path = $upload_dir['path']."/";
		$url = $upload_dir['url']."/";
		$u = mf_u_key();
		$name = sanitize_file_name($name);
		if(!empty($name))
			move_uploaded_file($temp, $path.$u.$name);
		return "\n[img]".$url.$u.$name."[/img]";
	}

	function MFGetExt($str)
	{
		//GETS THE FILE EXTENSION BELONGING TO THE UPLOADED FILE
		$i = strrpos($str,".");
		if (!$i) { return ""; }
		$l = strlen($str) - $i;
		$ext = substr($str,$i+1,$l);
		return $ext;
	}

	function mf_check_uploaded_images()
	{
		$valid = array('im1' => true, 'im2' => true, 'im3' => true);
		if($_FILES["mfimage1"]["error"] > 0 && !empty($_FILES["mfimage1"]["name"]))
			$valid['im1'] = false;
		if($_FILES["mfimage2"]["error"] > 0 && !empty($_FILES["mfimage2"]["name"]))
			$valid['im2'] = false;
		if($_FILES["mfimage3"]["error"] > 0 && !empty($_FILES["mfimage3"]["name"]))
			$valid['im3'] = false;
		if(!empty($_FILES["mfimage1"]["name"]))
		{
			$ext = strtolower(MFGetExt(stripslashes($_FILES["mfimage1"]["name"])));
			if($ext != "jpg" && $ext != "jpeg" && $ext != "bmp" && $ext != "png" && $ext != "gif")
				$valid['im1'] = false;
		}
		else
			$valid['im1'] = false;
		if(!empty($_FILES["mfimage2"]["name"]))
		{
			$ext = strtolower(MFGetExt(stripslashes($_FILES["mfimage2"]["name"])));
			if($ext != "jpg" && $ext != "jpeg" && $ext != "bmp" && $ext != "png" && $ext != "gif")
				$valid['im2'] = false;
		}
		else
			$valid['im2'] = false;
		if(!empty($_FILES["mfimage3"]["name"]))
		{
			$ext = strtolower(MFGetExt(stripslashes($_FILES["mfimage3"]["name"])));
			if($ext != "jpg" && $ext != "jpeg" && $ext != "bmp" && $ext != "png" && $ext != "gif")
				$valid['im2'] = false;
		}
		else
			$valid['im3'] = false;
		return $valid;
	}

	$mingleforum->setup_linksdk($_POST['add_topic_plink']);
	$options = get_option("mingleforum_options");

	//--weaver-- check if guest filled in form
	if (!isset($_POST['edit_post_submit'])) {
		$errormsg = apply_filters('wpwf_check_guestinfo',"");
		if ($errormsg != "") {
			$error = true;
			wp_die($errormsg); //plugin failed
		}
	}
	//--weaver-- end guest form check

	if($options['forum_captcha'] == true && !$user_ID){
		include_once(WPFPATH."captcha/shared.php");
		$wpf_code = wpf_str_decrypt($_POST['wpf_security_check']);
			if(($wpf_code == $_POST['wpf_security_code']) && (!empty($wpf_code))) {
			  //It passed
			}
			else {
				$error = true;
				$msg = __("Security code does not match", "mingleforum");
				wp_die($msg);
			}
	}

	$cur_user_ID = apply_filters('wpwf_change_userid', $user_ID); // --weaver-- use real id or generated guest ID

  //ADDING A NEW TOPIC?
	if(isset($_POST['add_topic_submit'])){
		$myReplaceSub = array("'", "\\");
		$subject = str_replace($myReplaceSub, "", $mingleforum->input_filter($_POST['add_topic_subject']));
		$content = $mingleforum->input_filter($_POST['message']);
		$forum_id = $mingleforum->check_parms($_POST['add_topic_forumid']);

		if($subject == ""){
			$msg .= "<h2>".__("An error occured", "mingleforum")."</h2>";
			$msg .= ("<div id='error'><p>".__("You must enter a subject", "mingleforum")."</p></div>");
			$error = true;
		}
		elseif($content == ""){
			$msg .=  "<h2>".__("An error occured", "mingleforum")."</h2>";
			$msg .=  ("<div id='error'><p>".__("You must enter a message", "mingleforum")."</p></div>");
			$error = true;
		}
		else{
			$date = $mingleforum->wpf_current_time_fixed('mysql', 0);
			
			$sql_thread = "INSERT INTO $mingleforum->t_threads 
						(last_post, subject, parent_id, `date`, status, starter) 
				 VALUES('$date', '$subject', '$forum_id', '$date', 'open', '$cur_user_ID')";
			$wpdb->query($wpdb->prepare($sql_thread));
			
			$id = $wpdb->insert_id;
			//Add to mingle board
			$myMingID = -1;
			if(!function_exists('is_plugin_active'))
				require_once( ABSPATH . 'wp-admin/includes/plugin.php' );
			if(is_plugin_active('mingle/mingle.php') and is_user_logged_in())
			{
				$board_post =& MnglBoardPost::get_stored_object();
				$myMingID = $board_post->create( $cur_user_ID, $cur_user_ID, "[b]".__("created the forum topic:", "mingleforum")."[/b] <a href='" . $mingleforum->get_threadlink($id) . "'>" . $mingleforum->output_filter($subject) . "</a>" );
			}
			//End add to mingle board

			//MAYBE ATTACH IMAGES
			$images = mf_check_uploaded_images();
			if($images['im1'] || $images['im2'] || $images['im3'])
			{
				if($images['im1'])
					$content .= MFAttachImage($_FILES["mfimage1"]["tmp_name"], stripslashes($_FILES["mfimage1"]["name"]));
				if($images['im2'])
					$content .= MFAttachImage($_FILES["mfimage2"]["tmp_name"], stripslashes($_FILES["mfimage2"]["name"]));
				if($images['im3'])
					$content .= MFAttachImage($_FILES["mfimage3"]["tmp_name"], stripslashes($_FILES["mfimage3"]["name"]));
			}

			$sql_post = "INSERT INTO $mingleforum->t_posts 
						(text, parent_id, `date`, author_id, subject)
				 VALUES('$content', '$id', '$date', '$cur_user_ID', '$subject')";
			$wpdb->query($wpdb->prepare($sql_post));
			$new_post_id = $wpdb->insert_id;
			
			//UPDATE PROPER Mngl ID
			$sql_thread = "UPDATE $mingleforum->t_threads
					SET mngl_id = $myMingID
					WHERE id = $id";
			$wpdb->query($wpdb->prepare($sql_thread));
			//END UPDATE PROPER Mngl ID
		}
		if(!$error){
			$mingleforum->notify_starter($id, $subject, $content, $date);
			$unused = apply_filters('wpwf_add_guest_sub', $id);	//--weaver-- Maybe add a subscription
			header("Location: ".html_entity_decode($mingleforum->get_threadlink($id)."#postid-".$new_post_id)); exit;
			}
		else
			wp_die($msg);

	}

  //ADDING A POST REPLY?
	if(isset($_POST['add_post_submit'])){
		$subject = $mingleforum->input_filter($_POST['add_post_subject']);
		$content = $mingleforum->input_filter($_POST['message']);
		$thread = $mingleforum->check_parms($_POST['add_post_forumid']);
		
		//GET PROPER Mngl ID
		$MngBID = $wpdb->get_var($wpdb->prepare("SELECT mngl_id FROM $mingleforum->t_threads WHERE id = $thread"));
		//END GET PROPER Mngl ID
		
		if($subject == ""){
			$msg .= "<h2>".__("An error occured", "mingleforum")."</h2>";
			$msg .= ("<div id='error'><p>".__("You must enter a subject", "mingleforum")."</p></div>");
			$error = true;
		}
		elseif($content == ""){
			$msg .=  "<h2>".__("An error occured", "mingleforum")."</h2>";
			$msg .=  ("<div id='error'><p>".__("You must enter a message", "mingleforum")."</p></div>");
			$error = true;
		}
		else{
			$date = $mingleforum->wpf_current_time_fixed('mysql', 0);
			//Add to mingle board
			if(!function_exists('is_plugin_active'))
				require_once( ABSPATH . 'wp-admin/includes/plugin.php' );
			if(is_plugin_active('mingle/mingle.php') and is_user_logged_in() and $MngBID > 0)
			{
				$board_post =& MnglBoardPost::get_stored_object();
				$mngl_board_comment->create( $MngBID, $cur_user_ID, "[b]".__("replied to the forum topic:", "mingleforum")."[/b] <a href='" . $mingleforum->get_threadlink($thread) . "'>" . $mingleforum->output_filter($subject) . "</a>" );
			}
			//End add to mingle board

			//MAYBE ATTACH IMAGES
			$images = mf_check_uploaded_images();
			if($images['im1'] || $images['im2'] || $images['im3'])
			{
				if($images['im1'])
					$content .= MFAttachImage($_FILES["mfimage1"]["tmp_name"], stripslashes($_FILES["mfimage1"]["name"]));
				if($images['im2'])
					$content .= MFAttachImage($_FILES["mfimage2"]["tmp_name"], stripslashes($_FILES["mfimage2"]["name"]));
				if($images['im3'])
					$content .= MFAttachImage($_FILES["mfimage3"]["tmp_name"], stripslashes($_FILES["mfimage3"]["name"]));
			}

			$sql_post = "INSERT INTO $mingleforum->t_posts 
						(text, parent_id, `date`, author_id, subject)
				 VALUES('$content', '$thread', '$date', '$cur_user_ID', '$subject')";
			$wpdb->query($wpdb->prepare($sql_post));
			$new_id = $wpdb->insert_id;
			$wpdb->query($wpdb->prepare("UPDATE $mingleforum->t_threads SET last_post = '$date' WHERE id = $thread"));
		}

		if(!$error){
			$mingleforum->notify_starter($thread, $subject, $content, $date);
			$unused = apply_filters('wpwf_add_guest_sub', $thread);	//--weaver-- Maybe add a subscription
			header("Location: ".html_entity_decode($mingleforum->get_paged_threadlink($thread)."#postid-".$new_id)); exit;
		}
		else	
			wp_die($msg);
	}

	//EDITING A POST?
	if(isset($_POST['edit_post_submit'])){
    $subject = $mingleforum->input_filter($_POST['edit_post_subject']);
    $content = $mingleforum->input_filter($_POST['message']);
    $thread = $mingleforum->check_parms($_POST['thread_id']);
    $edit_post_id = $_POST['edit_post_id'];

    if($subject == ""){
    $msg .= "<h2>".__("An error occured", "mingleforum")."</h2>";
    $msg .= ("<div id='error'><p>".__("You must enter a subject", "mingleforum")."</p></div>");
    $error = true;
    }
    elseif($content == ""){
    $msg .= "<h2>".__("An error occured", "mingleforum")."</h2>";
    $msg .= ("<div id='error'><p>".__("You must enter a message", "mingleforum")."</p></div>");
    $error = true;
    }

    if ($error) wp_die($msg);

	//SECURITY FIX NEEDED
    $sql = ("UPDATE $mingleforum->t_posts SET text = '$content', subject = '$subject' WHERE id = $edit_post_id");
	$wpdb->query($wpdb->prepare($sql));

    $ret = $wpdb->get_results($wpdb->prepare("select id from $mingleforum->t_posts where parent_id = $thread order by date asc limit 1"));
    if ($ret[0]->id == $edit_post_id) {
    $sql = ("UPDATE $mingleforum->t_threads set subject = '$subject' where id = '$thread'");
    $wpdb->query($wpdb->prepare($sql));
    }

    header("Location: ".html_entity_decode($mingleforum->get_paged_threadlink($thread)."#postid-".$edit_post_id)); exit;
	}
?>