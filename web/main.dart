import 'package:angular/angular.dart';
import 'dart:convert';
import 'dart:html';

var host = "127.0.0.1:8080";

@NgController(
    selector: '[tutorial-content]',
    publishAs: 'ctrl'
)
class TutorialController {
  static const String LOADING_MESSAGE = "Loading...";
  static const String ERROR_MESSAGE = "Oh no! An error has occured.";
  
  //static const bool live = false;
  
  int state = 0; // 0 = story, 1 = no story, 2 = no goal
  
  String currentURL;
  
  List<Page> pages = [];
  
  int currentPageIndex;
  Page quickref = new Page("Quick Reference", "./tutorial/quickref.html");
  
  //change this back to 0 before running live study
  int furthestPageIndex = 0;
  
  Http _http;
  bool story = true;
  
  List<String> surveyIDs = ["57L3HGR", "F8RWKYF", "F8FFMBN", "F8G2CLM", "F8BLFDT"];
  int surveyIndex = 0;
  
  //String activeCondition;
  //List conditions = ["Story", "No Story"];
  
  TutorialController(Http this._http) {
    _loadPages();
  }
  
  toggleStory() {
    
    // increment state
    state++;
    if (state>2) {
      state = 0;
    }
    
    // set story variable
    if (state==0) {
      story = true;
    } else {
      story = false;
    }
  }
    
  
  goTo(Page page) {
    DateTime now = new DateTime.now();
    print("$now: Going from '${pages[currentPageIndex].name}' to '${page.name}'");
    int pageIndex = pages.indexOf(page);
    if (pageIndex <= furthestPageIndex+1) {
        currentPageIndex = pageIndex;
        if (furthestPageIndex < pageIndex) {
          furthestPageIndex = pageIndex;
        }
    }
    currentURL=getCurrentURL();

  }
  
  String getCurrentURL() {
    print ("current URL: ${pages[currentPageIndex].contentURL}");
    print("current page index: $currentPageIndex");
    return pages[currentPageIndex].contentURL;
  }
  
  navMenuGoTo(Page page) {
    DateTime now = new DateTime.now();
    print("$now: Going from '${pages[currentPageIndex].name}' to '${page.name}'");
    int pageIndex = pages.indexOf(page);
    if (pageIndex <= furthestPageIndex) {
        currentPageIndex = pageIndex;
        if (furthestPageIndex < pageIndex) {
          furthestPageIndex = pageIndex;
        }
    }
    currentURL=getCurrentURL();
  }
  
  popupDemographicSurvey() {
    DateTime now = new DateTime.now();
    print("$now: Launching demographic survey");

    var popup = window.open("http://www.surveymonkey.com/s/8TKRFVS", "Short Survey", "width=600, height=700, status=1");
    justNextButton();

  }
  
  popupShortSurvey(int surveyNum) {
    DateTime now = new DateTime.now();
    print("$now: Launching short survey ${surveyNum}");
    
    var popup = window.open("https://www.surveymonkey.com/s/${surveyIDs[surveyNum]}", "Short Survey", "width=600, height=700, status=1");
    //listen for window.closed?
    //surveyIndex++;
    justNextButton();
  }
  
  popupFinalSurvey() {
    DateTime now = new DateTime.now();
    print("$now: Launching final survey");
    var popup = window.open("https://www.surveymonkey.com/s/5JSBWF6", "Short Survey", "width=600, height=700, status=1");
  }
  
  justNextButton(){
    Element content = querySelector("#content");
    //remove content
    content.children.clear();
    //replace with 'Next' button
    var nextButton = new Element.html('<button class="btn btn-primary">Next</button>');
    nextButton.onClick.listen((e)=>nextPage());

    content.children.add(nextButton);
  }
  
  int frameNum(int offset) {
    if (!story) {
      return offset + 3;
    } else {
      return offset + 122; //was 122
    }
  }
  
  String getActiveVideo() {
    if (story) {
      return "RedBallIntro.webm";
    } else {
      return "nostory_preview.webm";
    }
  }
  
  nextPage([String returnVal]) {
    goTo(pages[currentPageIndex+1]);
  }
  
  void launchBlender() {
    HttpRequest request = new HttpRequest(); // create a new XHR

    request.onReadyStateChange.listen((_) {
      if (request.readyState == HttpRequest.DONE &&
          (request.status == 200 || request.status == 0)) {
        // data saved OK.
        print(request.responseText); // output the response from the server
      }
    });
    
    // POST the data to the server
    var url = "http://$host/launch-blender";

    if (!story) {
      var url = "http://$host/launch-blender-nostory";
    }
    request.open("POST", url, async:false);
    
    String jsonData = '{"language":"dart"}'; // etc...
    request.send(JSON.encode(jsonData));
    
    nextPage();
    
  }
  
  
  List<Page> _loadPages() {
    _http.get("tutorial.json")
      .then(
      (HttpResponse response) {
        print(response);
        for (Map page in response.data) {
          if (state==0){
            pages.add(new Page.fromJsonMap(page));
          }
          if (state==1 && page['contentURL'] != "./tutorial/storyinset.html") {
            pages.add(new Page.fromJsonMap(page));
          }
          if (state==2 && page['contentURL'] != "./tutorial/storyinset.html" && page['contentURL'] !="./tutorial/introduction.html") {
            pages.add(new Page.fromJsonMap(page));
          }
        }

        if (state==0) {
          story = true;
        } else {
          story = false;
        }
        currentPageIndex = 0;
        currentURL=pages[0].contentURL;

      },
      onError: (Object obj) {
        print(obj);  
      });
  }
}

class Page {
  String name;
  String contentURL;
  
  Page(this.name, this.contentURL);
  
  factory Page.fromJsonMap(Map json){
    return new Page(json['name'], json['contentURL']);
  }
}




main() {
  var module = new Module()
    ..type(TutorialController);
  ngBootstrap(module: module);
}
