////////////Образец игрв Pacman на базе модуля GRAPH3D//////////////////////////

uses controls, graph3d;

////////////////////ОПИСЫВАЕМ НАПРАВЛЕНИЯ ДВИЖЕНИЯ//////////////////////////////
type
  directions = (up, right, down, left, none);

//////////СОЗДАЕМ КЛАСС ДЛЯ ОПИСАНИЯ ВОЗМОЖНЫХ ПУТЕЙ ДВИЖЕНИЯ В МАТРИЦЕ/////////
type
  cell = record
    x, y, cost: integer;
    dir: directions;
  end;

///////////////////Описываем класс для объявлеия врагов/////////////////////////  
type
  enemy = class
    x, y: integer; //положение в матрице лабиринта
    next_time := 0;
    anim_duration := 500;
    dir: directions;//направление движения противника
    model: spheret;//3D модель
    cost: array [,] of integer;//матрица стоимости пути для алгоритма выбора пути
    constructor create(limx, limy, _x, _y: integer);
    begin
      cost := MatrFill(limx + 1, limx + 1, 1);//заполняем матрицу 1
      x := _x;//выставляем x,y
      y := _y;
      model := sphere(x, y, 0.5, 0.5, colors.red);//создаем призрака по целочисленными координатам в матрице
      model.AddChild(cylinder(0, 0, -0.5, 0.5, 0.5, colors.red));//дорисовываем призрака
      model.AddChild(sphere(-0.3, -0.2, 0, 0.2, colors.White));
      model.AddChild(sphere(-0.3, 0.2, 0, 0.2, colors.White));
      model.AddChild(sphere(-0.35, -0.22, 0, 0.15, colors.black));
      model.AddChild(sphere(-0.35, 0.22, 0, 0.15, colors.black));
      model.Rotate(ortx, -90);
      model.Rotate(ortz, 90);
      case random(1, 4) of //случайным образом выполняем выбор напрпавления
        1: dir := up;
        2: dir := right;
        3: dir := down;
        4: dir := left;
      end;
    end;
    /////////////ФУНКЦИЯ ПРЕОБРАЗОВАНИЯ НАПРАВЛЕНИЯ В ПРИРАЩЕНИЕ КООРДИНАТ//////////
    function k(dir: directions): Point3D;//В ЗАВИСИМОСТИ ОТ НАПРАВЛЕНИЯ
    begin
      case dir of
        up: result := P3D(0, -1, 0.5);
        right: result := P3D(1, 0, 0.5);
        down: result := P3D(0, 1, 0.5);
        left: result := P3D(-1, 0, 0.5);
      end;
    end;
    
    function createcell(x, y, c: integer; d: directions): cell;
    begin
      result.x := x;
      result.y := y;
      result.dir := d;
      result.cost := c;
    end;
    
    procedure move(limx, limy: integer; field: array [,] of char);//процедура движения врага
    begin
      if next_time > milliseconds then exit;
      cost[x, y] += 1;//увеличиваем стоимость текущей клетки на +1
      var listcell := new List<cell>;//создаем пустой список доступных клеток для движения
          ////////////////////////////////////////////////////////////////////////////////
      for var i := up to left do //перебираем все направления
      begin //для каждого из направлений
        var (nx, ny) := (x + round(k(i).x), y + round(k(i).y));//получаем черех функцию K новые координаты клетки по выбранному направлению
        if (nx in 0..limx) and (ny in 0..limy) and (field[nx, ny] <> 'x') then  //проверяем чтобы координаты находились в пределах массива и на них не было препятствий (0)                     
          listcell.Add(Createcell(nx, ny, cost[nx, ny], i));//и добавляем данные в список доступных клеток для движения пользуясь конструктором автокласса (индейская хитрость)
      end;
          //////отбираем клетку с минимальнйо стоимостью и двигаемся на нее///////
      var nextcell:cell;
      try
        listcell.Shuffle;//перемешиваем все доступные направления для более хаотичного перемещения
        nextcell:=listcell.MinBy(t -> t.cost);
        x := nextcell.x;//получаем новые координаты в матрице
        y := nextcell.y;//
        dir := nextcell.dir;//задаем новое направление
        model.AnimMoveTo(x, y, model.Position.z, anim_duration/1000).begin;//выполняем анимированное передвижение на новые координаты x,y за время 0.5 c
        //model.MoveTo(x, y,model.Position.z);
        next_time := milliseconds + anim_duration;
      except; //пропускаем ошибку
      end;//если таких клеток не будет программа завершится с ошибкой поэтому используем try      
    end;
  end;
////////////////////////ОПИСЫВАЕМ КЛАСС ДЛЯ PACMAN//////////////////////////////
type
  player = class
    x, y: integer; //положение в матрице
    dead: boolean;
    next_time := 0;
    anim_duration := 400;
    dir: directions;//направление движения
    model: spheret;//3d модель
    modelobj: FileModelT;
    ku, kd, kl, kr: boolean;//буферные переменные для нажатых кнопок управления
    constructor create(_x, _y: integer);
    begin
      x := _x;
      y := _y;
      modelobj:=graph3d.FileModel3D(x,y,0.5,'pacman.obj',colors.yellow);
      model := sphere(x, y, 0.5, 0.45, colors.yellow);
      //model.AddChild(sphere(-0.15, 0.15, 0.2, 0.2, colors.White));
      model.Visible:=false;
      //model.AddChild(cone(0, -0.5, 0, 0.5,0.5, colors.black));
    end;
    
    procedure move(newx, newy: integer; newdir: directions); //аналогично процедуре из класса enemy
    begin
      x := newx;
      y := newy;
      if dir<>newdir then 
             case newdir of
               up: modelobj.rotate(orty,-180);
               down: modelobj.rotate(orty,180);
               left: modelobj.rotate(ortx,-180);
               right: modelobj.rotate(ortx,180);
             end;
      dir := newdir;
      model.AnimMoveTo(x, y, model.Position.z, anim_duration/1000).begin;
      modelobj.AnimMoveTo(x, y, model.Position.z, anim_duration/1000).begin;
      next_time:=milliseconds+anim_duration;
    end;
  end;

begin
  view3d.HideAll;//отключаем доп элементы 3d
  view3d.BackgroundColor := colors.black;//устанавливаем цвет фон
  LeftPanel(150, Colors.Orange);
  var sbar := statusbar();
  var stagename := 'stage1.txt';
  var ghosts := new List<enemy>;//список приведений
  var foods := new List<cubet>;//список еды
  var walls := new List<cubet>;//список стен (можно и без него)
  var pacman: player;//создаем пакмена
  var gameovertext: TextT;
  var ScoreText: TextT;
  var wintext: TextT;
  //sbar.AddText('Количество объектов',300);
  var r1 := radiobutton('Уровень 1');
  r1.Click := procedure -> stagename := 'stage1.txt';
  r1.Checked := true;
  var r2 := radiobutton('Уровень 2');
  r2.Click := procedure -> stagename := 'stage2.txt';
  var r3 := radiobutton('Уровень из файла');
  var custom_stage:=textbox;
  custom_stage.text:='stage11.txt';
  button('Загрузить').Click := () ->begin
                                    if r3.Checked then 
                                      begin
                                       stagename:=custom_stage.Text;
                                       sbar.Text:='Выбран уровень '+custom_stage.Text;
                                      end;
                                    end;
  button('Играть').Click := () ->
  begin
    ghosts.foreach(t -> begin t.model.Destroy end);
    ghosts.Clear;
    foods.foreach(t -> begin t.Destroy end);
    foods.Clear;
    walls.foreach(t -> begin t.Destroy end);
    walls.Clear;
    try
      gameovertext.destroy except end;
    try
      wintext.destroy except end;
    try
      ScoreText.destroy except end;
    object3dlist.foreach(t -> begin t.Destroy end);
    object3dlist.Clear;
    /////////////////////////загрузка карты из файла//////////////////////////////
    var f: text;//создаем перменную для работы с файлом
    reset(f, stagename);//окрываем на чтение
    var limx, limy: integer; //объявляем перменные для хранения размера карты
    var field:array [,] of char;
    try
    readln(f, limx);//считываем размер по x
    readln(f, limy);//считываем размер по y
    field := matrfill(limx, limy, ' ');//создаем пустую матрицу указанного размера
    limx -= 1;//уменьшаем перменные для удобства использованя в циклах
    limy -= 1;//
    for var i := limx to 0 step -1 do
      for var j := 0 to limy do
      begin
        var c: char;//объявляем перменную для считываения символа
        repeat
          c := f.ReadChar; //читаем в переменную c
        until c > ' '; //если символ непечатный читаем следующий 
        field[j, i] := c; //заносим символ в матрицу карты
        case c of //визуализируем соотвествующий символ на экране
          'x': walls.Add(cube(j, i, 0.5, 1, diffusematerial(colors.blue)));
          //'.': foods.Add(sphere(j, i, 0.5, 0.1, emissivematerial(colors.white)));
          '.': foods.Add(cube(j, i, 0.5, 0.1, emissivematerial(colors.white)));
          'g': ghosts.Add(new enemy(limx, limy, j, i));//передаем размеры матрицы для создания собственной матрицы стоимости
          'p': pacman := new player(j, i);
        end;
      end;
    f.Close;
    except sbar.Text:='Ошибка в файле уровня'; exit end;
    //////////////////////////////Создаем переменные//////////////////////////////
    window.Title := 'Pacman v0.1';
    var score := 0;//счет
    var gameover := false;//флаг окончания игры
    var win := false;//флаг победы
    //pacman.modelobj:= 0.45;
    gameovertext := text3d(limx / 2, limy / 2, 0, 'YOU LOSE', 2);
    ScoreText := Text3D(-2.5, limy - 1, 0, 'Score: 0', 0.5); //выводим на экран счёт
    scoretext.Color := colors.LightYellow;
    scoretext.Rotate(ortx, -90);//разворачиваем надпись к нам лицом
    
    //устанавливаем камеру
    camera.Position := p3d(limx / 2, limy / 2, seq(limx, limy).max * 2);
    camera.UpDirection := v3d(0, 1, 0);
    camera.LookDirection := v3d(0, 0, -30);
    ///////////////////////////обработчик клавиатуры//////////////////////////////
    onkeydown := k -> begin
      case k of
        key.Up: pacman.ku := true;
        key.Down: pacman.kd := true;
        key.Left: pacman.kl := true;
        key.Right: pacman.kr := true;
      end;
    end;
    onkeyup := k -> begin
      case k of
        key.Up: pacman.ku := false; 
        key.Down: pacman.kd := false;
        key.Left: pacman.kl := false;
        key.Right: pacman.kr := false;
      end;
    end;
    //обработчик кадров
    //ondrawframe := dt -> begin
    BeginFrameBasedAnimationTime(procedure (dt)-> begin
      sbar.ItemText[0] := 'Количество объектов:' + object3dlist.Count.ToString;
      if GAMEOVER then exit;//если не конец игры то выполнем тело программы
      
      if pacman.dead then //если пакмен погиб
      begin
        ;//выводим на экран сообщение
        gameovertext.Color := colors.OrangeRed;
        gameovertext.Rotate(ortx, -90);//разворачиваем надпись к нам лицом
        gameovertext.AnimMovebyZ(11, 2).Begin;//запускаем анимацию
        gameover := true;//заканчиваем игру
      end;
      
      if (pacman.next_time< milliseconds) and (pacman.ku or pacman.kd or pacman.kl or pacman.kr) then //если пропускемые кадры закончились и нажата кнопка движения
      begin
        //if field[pacman.x,pacman.y]='.' then (field[pacman.x,pacman.y], score):=(' ',score+1);
        var (nx, ny) := (pacman.x, pacman.y);//для новых координат создаем временную переменную и помещаем туда текущие
        if pacman.ku then pacman.dir := up;   //по нажатой кнопке выбираем направление движения, 
        if pacman.kd then pacman.dir := down; //согласно кода программы нажаты могут быть все кнопки 
        if pacman.kl then pacman.dir := left; //но реагировать управление должно на последнююю нажатую
        if pacman.kr then pacman.dir := right;
        case pacman.dir of  //исходя из выбранного направления выполняем приращение координат
          up: ny += 1;
          down: ny -= 1;
          left: nx -= 1;
          right: nx += 1;
        end;
        if (nx in 0..limx) and (ny in 0..limy) and (field[nx, ny] <> 'x') then  //проверяем чтобы по новым координатам игрок находялися в поле и не попал на препятствия
        begin
          pacman.move(nx, ny, pacman.dir); //двигаем пакмена на новые координаты
        end;
        scoretext.Text := 'Score:' + score.ToString;
      end;
      //////////////////////////Алгоритм движения врагов//////////////////////////
      foreach var ghost in ghosts do //перебираем всех врагов
      begin
        //если пакмена съело приведение
        var distance := sqrt((pacman.model.Position.X - ghost.model.Position.x) ** 2 + (pacman.model.Position.y - ghost.model.Position.y) ** 2);
        if distance < pacman.model.Radius then
        begin
          pacman.dead := true;//выставлем перменную гибели
          pacman.modelobj.AnimScale(0, 1).Begin;//анимация гибели
        end;
        ghost.move(limx, limy, field);
      end;
     
     foreach var food in foods do//проваеряем на еду
          if (abs(pacman.model.Position.X - food.x) < food.SideLength) and (abs(pacman.model.Position.y - food.y) < food.SideLength) and food.Visible then (food.visible, score) := (false, score + 1);
     if (foods.Where(t -> t.visible).Count = 0) and not win then //если съедена вся еда то включаем победу
      begin
        wintext := text3d(limx / 2, limy / 2, 0, 'YOU WIN', 2);//выводим на экран сообщение
        wintext.Color := colors.LimeGreen;
        wintext.Rotate(ortx, -90);//разворачиваем надпись к нам лицом
        wintext.AnimMovebyZ(12, 5).Begin;//запускаем анимацию
        win := true;//включаем победу
        gameover := true;//заканчиваем игру
      end;
      
    end);
  end;
end.