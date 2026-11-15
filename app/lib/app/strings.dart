/// Everything the screens say that is not part of a level (levels.dart has
/// the levels' own lines), in Traditional Chinese (Taiwan).
abstract final class Strings {
  static const appName = '安全小隊';

  // The base.
  static String hello(String name) => '$name，歡迎回到小隊基地！今天要去哪個世界？';
  static String member(String name) => '小隊員：$name';
  static const helmet = '安全帽';
  static String badgeCount(int n, int of) => '徽章 $n／$of';
  static const parent = '家長';
  static const locked = '完整版才有喔，請爸爸媽媽看看。';
  static const back = '回去';
  static const home = '回基地';
  static const again = '再聽一次';

  // A world.
  static String worldHello(String helper, String world) => '我是$helper！歡迎來到$world，點一關開始吧。';
  static String levelIntro(String zh, String learn) => '$zh：$learn。';

  // The end of a level.
  static const wellDone = '做得好！';
  static const forParent = '給爸爸媽媽';
  static const realLife = '回真實生活做做看';
  static const playAgain = '再玩一次';
  static const nextLevel = '下一關';
  static const toWorld = '回世界';
  static String gotBadge(String zh) => '「$zh」的徽章，貼到安全帽上了！';
  static String gotCrest(String helper) => '整個世界都做完了！$helper敬禮，送你隊徽！';

  // The helmet page.
  static const helmetTitle = '安全小勇士';
  static const helmetSay = '這是你的安全帽，做完一關就貼一個徽章。';
  static const crests = '隊徽';
  static const gold = '真實生活金徽章';
  static const goldNote = '爸爸媽媽在家長模式打勾，就會得到金徽章。';

  // The first start.
  static const setupTitle = '選你的小隊員';
  static const setupSay = '你是安全小隊的小隊員！選一選你的樣子。';
  static const hair = '髮型';
  static const skin = '膚色';
  static const helmetColor = '安全帽';
  static const go = '出發！';

  // The note before 身體世界.
  static const introTitle = '給爸爸媽媽：身體世界';
  static const introParas = [
    '這個世界教小朋友「身體紅綠燈」：手、頭、肩膀是綠燈（握手、擊掌可以）；臉和肚子是黃燈（要先問我）；泳衣遮住的地方是紅燈（是自己的，別人不可以看、不可以摸）。',
    '還有：不舒服的時候可以大聲說「不要！」；別人說不要，我們也要停下來；有不舒服或怪怪的事，要告訴信任的大人，不是你的錯。',
    '畫面都是平常、平靜的情境，沒有壞人，也沒有可怕的畫面。爸爸媽媽幫忙洗澡、醫生看病而且爸媽在旁邊，是可以的。',
    '建議陪小朋友一起玩，玩完用每一關最後的問題卡聊一聊。信任的大人可以在家長模式選（2～4 個）。',
    '如果現在不想讓小朋友玩，可以在家長模式把「身體世界」關掉。',
  ];
  static const introOk = '我看過了，開始';
  static const introLater = '先回基地';

  // The rest.
  static const restTitle = '休息時間到了！';
  static const restLine = '幫手們回基地休息，安全帽掛起來了。換你去真的地方做做看！';

  // The parent gate.
  static const callParent = '請爸爸媽媽來';
  static const parentGateTitle = '家長確認';
  static String gateQuestion(String a, String b) => '$a 加 $b 等於多少？';
  static const gateRules = '答對才能進家長模式';
  static const wrongAnswer = '不對喔，再試一次';
  static String gateWait(int s) => '請等 $s 秒再試';
  static const cancel = '取消';
  static const backspace = '刪掉';

  // Parent mode.
  static const parentTitle = '家長模式';
  static const sMember = '小隊員';
  static const name = '名字（可以不填，就叫「小隊員」）';
  static const changeLook = '換樣子';
  static const age = '年齡';
  static const minutes = '每次玩多久';
  static const sLost = '走失的時候要說的';
  static const phone = '爸爸媽媽的電話';
  static const phoneNote = '只存在這支手機裡，用來在「走失了」那關練習背。不存地址、不存全名。';
  static const phoneSaved = '已存好';
  static const phoneBad = '請輸入 6～12 個數字';
  static const calls = '小朋友叫他';
  static const sTrusted = '安全大人（選 2～4 個）';
  static const trustedNote = '「說不要」那關最後，兔兔會請小朋友有不舒服的事去跟他們說。';
  static const sWorlds = '要開哪些世界';
  static const bodyNote = '可以關掉；第一次進去會先給你看說明。';
  static const sProgress = '進度';
  static const sReal = '真實生活清單（打勾就給金徽章）';
  static const sCheat = '家長小抄';
  static const sSound = '聲音';
  static const music = '背景音樂';
  static const sounds = '音效';
  static const voice = '念出來';
  static const full = '完整版（測試中先全部打開）';
  static const freeNote = '免費版：馬路世界全部和地震那一關。';
  static const bodyIntroAgain = '再看一次身體世界的說明';
  static String plays(int n) => n == 0 ? '還沒玩' : '玩了 $n 次';
  static String version(String v) => '版本 $v';
}
