# Milk_the_Chimp_Robot
### Team members: Hua Shao, Shiyi Zhou, and Zexi Liu

This project proposes to develop the digital components of a robot that does the line following.

## Description

![The "Robot"](https://github.com/suanming1991/Milk_the_Chimp_Robot/blob/master/imgs/bottomView.PNG)

An array of six IR sensors will be utilized by the A2D converter and the readings will be
mathematically combined to form a signed error signal (Positive if too far left of the line, negative if too
far right of the line). This error signal will be used in a PID control algorithm to determine the drive to
each motor pair (left/right) to steer the follower. The digital core provides an 11-bit signed number
for each motor pair (left/right) that represents the magnitude and direction (forward/reverse). The
Motor Cntrl block converts these numbers into PWM signals that then drive the motors (through an
external driver chip). There are stations along the path of the line that will have “barcodes”. A 7th IR
sensor (that sits to the extreme left of the follower) is configured to give a serial bit stream as the
follower drives over a station ID barcode. The follower will receive a command from the Bluetooth
module (sent via UART) to go to a specific station and stop there. There is also a forward looking
proximity sensor (looks 10cm ahead). If the path is clear it asserts OK2Move. If this signal falls the
follower should hit the brakes and buzzes the piezo buzzer.

## Modules

![Module Overview](https://github.com/suanming1991/Milk_the_Chimp_Robot/blob/master/imgs/projectOverview.PNG)

The system is divided into several modules. The description of each is listed below.

<!---
| Module              | Contains                                                                                            | Docs                         |
| ------------------- | --------------------------------------------------------------------------------------------------- | ---------------------------- |
| **Digital Core**    | **Included in any build**. Gets you started and has the working-with-your-data functions.           | [Doc](./docs/sheetsee-core.md)   |
| **A2D Interface**   | Contains everything you'll need to create a table including sortable columns, pagination and search.| [Doc](./docs/sheetsee-tables.md) |
| **Barcode Reader**  | For making maps with your point, line or polygon spreadsheet data. Built on Mapbox.js.              | [Doc](./docs/sheetsee-maps.md)   |
| **UART**  | Includes 3 basic d3 charts: bar, line and pie. You can also [use your own](docs/custom-charts.md).  | [Doc](./docs/sheetsee-charts.md) |
| **Motor Control**   | Includes 3 basic d3 charts: bar, line and pie. You can also [use your own](docs/custom-charts.md).  | [Doc](./docs/sheetsee-charts.md) |
-->

<html>
<head>
<style>

</style>
</head>
<body>

<table style="width:100%">
  <tr>
    <th>Module</th>
    <th>Contains</th>
    <th>Docs</th>
  </tr>
  <tr align="center">
    <td>A2D interface</td>
    <td>Interface that changes analog signal to digital counterpart</td>
    <td>NA</td>
  </tr>
  <tr align="center">
    <td>Digital Core</td>
    <td>Core function of the robot which does major calculation/logic processing</td>
    <td>NA</td>
  </tr>
  <tr align="center">
    <td>Barcode Reader</td>
    <td>Reader that reads the barcode at the station to stop</td>
    <td>NA</td>
  </tr>
  <tr align="center">
    <td>UART</td>
    <td>Bluetooth UART module that receives signal from Bluegigia BLE module</td>
    <td>NA</td>
  </tr>
  <tr align="center">
    <td>Motor Control</td>
    <td>sends out PWM signal to control motor</td>
    <td>NA</td>
  </tr>
</table>

</body>
</html>

