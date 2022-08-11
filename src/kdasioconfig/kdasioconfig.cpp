/****************************************************************************
** KoordASIO
*/
#include <QFile>
#include <QTextStream>
#include <QDir>
#include "kdasioconfig.h"
#include "toml.h"
#include <QDebug>
#include <QProcess>
#include <QDialog>
#include <QTextBrowser>
#include <QColor>
#include <QDesktopServices>

KdASIOConfigBase::KdASIOConfigBase(QWidget *parent)
    : QMainWindow(parent)
{
    setupUi(this);
}

KdASIOConfigBase::~KdASIOConfigBase() {}

KdASIOConfig::KdASIOConfig(QWidget *parent)
    : KdASIOConfigBase(parent)
{
    this->setAttribute(Qt::WA_AlwaysShowToolTips,true);

    // init mmcpl proc
    mmcplProc = nullptr;

    // set up signals
    connect(sharedPushButton, &QPushButton::clicked, this, &KdASIOConfig::sharedModeSet);
    connect(exclusivePushButton, &QPushButton::clicked, this, &KdASIOConfig::exclusiveModeSet);
    connect(inputDeviceBox, QOverload<int>::of(&QComboBox::activated), this, &KdASIOConfig::inputDeviceChanged);
    connect(outputDeviceBox, QOverload<int>::of(&QComboBox::activated), this, &KdASIOConfig::outputDeviceChanged);
    connect(inputAudioSettButton, &QPushButton::pressed, this, &KdASIOConfig::inputAudioSettClicked);
    connect(outputAudioSettButton, &QPushButton::pressed, this, &KdASIOConfig::outputAudioSettClicked);
    connect(bufferSizeSlider, &QSlider::valueChanged, this, &KdASIOConfig::bufferSizeChanged);
    connect(bufferSizeSlider, &QSlider::valueChanged, this, &KdASIOConfig::bufferSizeDisplayChange);
    // connect footer buttons
    connect(koordLiveButton, &QPushButton::pressed, this, &KdASIOConfig::koordLiveClicked);
    connect(githubButton, &QPushButton::pressed, this, &KdASIOConfig::githubClicked);
    connect(versionButton, &QPushButton::pressed, this, &KdASIOConfig::versionButtonClicked);
    // for URLs
    koordLiveButton->setCursor(Qt::PointingHandCursor);
    githubButton->setCursor(Qt::PointingHandCursor);
    versionButton->setCursor(Qt::PointingHandCursor);

    // populate input device choices
    inputDeviceBox->clear();
    const auto input_devices = m_devices->audioInputs();
    for (auto &deviceInfo: input_devices)
        inputDeviceBox->addItem(deviceInfo.description(), QVariant::fromValue(deviceInfo));

    // populate output device choices
    outputDeviceBox->clear();
    const auto output_devices = m_devices->audioOutputs();
    for (auto &deviceInfo: output_devices)
        outputDeviceBox->addItem(deviceInfo.description(), QVariant::fromValue(deviceInfo));


    // parse .KoordASIO.toml
    std::ifstream ifs;
    ifs.exceptions ( std::ifstream::failbit | std::ifstream::badbit );
    try {
        ifs.open(fullpath.toStdString(), std::ifstream::in);
        toml::ParseResult pr = toml::parse(ifs);
        qDebug("Attempted to parse toml file...");
        ifs.close();
        if (!pr.valid()) {
            setDefaults();
        } else {
            setValuesFromToml(&ifs, &pr);
        }
    }
    catch (std::ifstream::failure e) {
        qDebug("Failed to open file ...");
        setDefaults();
    }

}

void KdASIOConfig::setValuesFromToml(std::ifstream *ifs, toml::ParseResult *pr)
{
    qInfo("We have parsed a valid TOML file.");
    // only recognise our accepted INPUT values - the others are hardcoded
    const toml::Value& v = pr->value;
    // get bufferSize
    const toml::Value* bss = v.find("bufferSizeSamples");
    if (bss && bss->is<int>()) {
        if (bss->as<int>() == 32||64||128||256||512||1024||2048) {
            bufferSize = bss->as<int>();
        } else {
            bufferSize = 64;
        }
        // update UI
        bufferSizeSlider->setValue(bufferSizes.indexOf(bufferSize));
        bufferSizeDisplay->display(bufferSize);
        // update conf
        bufferSizeChanged(bufferSizes.indexOf(bufferSize));
    }
    // get input stream stuff
    const toml::Value* input_dev = v.find("input.device");
    if (input_dev && input_dev->is<std::string>()) {
        // if setCurrentText fails some sensible choice is made
        inputDeviceBox->setCurrentText(QString::fromStdString(input_dev->as<std::string>()));
        inputDeviceChanged(inputDeviceBox->currentIndex());
    } else {
        inputDeviceBox->setCurrentText("Default Input Device");
        inputDeviceChanged(inputDeviceBox->currentIndex());
    }
    const toml::Value* input_excl = v.find("input.wasapiExclusiveMode");
    if (input_excl && input_excl->is<bool>()) {
        exclusive_mode = input_excl->as<bool>();
    } else {
        exclusive_mode = false;
    }
    // get output stream stuff
    const toml::Value* output_dev = v.find("output.device");
    if (output_dev && output_dev->is<std::string>()) {
        // if setCurrentText fails some sensible choice is made
        outputDeviceBox->setCurrentText(QString::fromStdString(output_dev->as<std::string>()));
        outputDeviceChanged(outputDeviceBox->currentIndex());
    } else {
        outputDeviceBox->setCurrentText("Default Output Device");
        outputDeviceChanged(outputDeviceBox->currentIndex());
    }
    const toml::Value* output_excl = v.find("output.wasapiExclusiveMode");
    if (output_excl && output_excl->is<bool>()) {
        exclusive_mode = output_excl->as<bool>();
    } else {
        exclusive_mode = false;
    }
    setOperationMode();

}

void KdASIOConfig::setDefaults()
{
    // set defaults
    qInfo("Setting defaults");
    bufferSize = 64;
    exclusive_mode = false;
    inputDeviceName = "Default Input Device";
    outputDeviceName = "Default Output Device";
    // set stuff - up to 4 file updates in quick succession
    bufferSizeSlider->setValue(bufferSizes.indexOf(bufferSize));
    bufferSizeDisplay->display(bufferSize);
    bufferSizeChanged(bufferSizes.indexOf(bufferSize));
    inputDeviceBox->setCurrentText(inputDeviceName);
    inputDeviceChanged(inputDeviceBox->currentIndex());
    outputDeviceBox->setCurrentText(outputDeviceName);
    outputDeviceChanged(outputDeviceBox->currentIndex());
    setOperationMode();
}


void KdASIOConfig::writeTomlFile()
{
    // REF: https://github.com/dechamps/FlexASIO/blob/master/CONFIGURATION.md
    // Write MINIMAL config to .KoordASIO.toml, like this:
    /*
        backend = "Windows WASAPI"
        bufferSizeSamples = bufferSize

        [input]
        device=inputDevice
        suggestedLatencySeconds = 0.0
        wasapiExclusiveMode = inputExclusiveMode

        [output]
        device=outputDevice
        suggestedLatencySeconds = 0.0
        wasapiExclusiveMode = outputExclusiveMode
    */
    QFile file(fullpath);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text))
        return;
    QTextStream out(&file);
    // need to explicitly set UTF-8 for non-ASCII character support
    out.setEncoding(QStringConverter::Utf8);
    // out.setCodec("UTF-8");
    //FIXME should really write to intermediate buffer, THEN to file - to make single write on file
    out << "backend = \"Windows WASAPI\"" << "\n";
    out << "bufferSizeSamples = " << bufferSize << "\n";
    out << "\n";
    out << "[input]" << "\n";
    out << "device = \"" << inputDeviceName << "\"\n";
    out << "suggestedLatencySeconds = 0.0" << "\n";
    out << "wasapiExclusiveMode = " << (exclusive_mode ? "true" : "false") << "\n";
    out << "\n";
    out << "[output]" << "\n";
    out << "device = \"" << outputDeviceName << "\"\n";
    out << "suggestedLatencySeconds = 0.0" << "\n";
    out << "wasapiExclusiveMode = " << (exclusive_mode ? "true" : "false") << "\n";
//    qDebug("Just wrote toml file...");

}

void KdASIOConfig::bufferSizeChanged(int idx)
{
    // select from 32 , 64, 128, 256, 512, 1024, 2048
    // This a) gives a nice easy UI rather than choosing your own integer
    // AND b) makes it easier to do a live-refresh of the toml file,
    // THUS avoiding lots of spurious intermediate updates on buffer changes
    bufferSize = bufferSizes[idx];
    bufferSizeSlider->setValue(idx);
    // Don't do any latency calculation for now, it is misleading as doesn't account for much of the whole audio chain
//    latencyLabel->setText(QString::number(double(bufferSize) / 48, 'f', 2));
    writeTomlFile();
}

void KdASIOConfig::bufferSizeDisplayChange(int idx)
{
    bufferSize = bufferSizes[idx];
    bufferSizeDisplay->display(bufferSize);
}

void KdASIOConfig::setOperationMode()
{
    if (exclusive_mode) {
        exclusiveModeSet();
    }
    else {
        sharedModeSet();
    }
}

void KdASIOConfig::sharedModeSet()
{
    sharedPushButton->setChecked(true);
//    qDebug() << "sharedButt: " << sharedPushButton->isChecked();
//    qDebug() << "exclusiveButt: " << exclusivePushButton->isChecked();
    exclusive_mode = false;
    writeTomlFile();
}

void KdASIOConfig::exclusiveModeSet()
{
    exclusivePushButton->setChecked(true);
//    qDebug() << "sharedButt: " << sharedPushButton->isChecked();
//    qDebug() << "exclusiveButt: " << exclusivePushButton->isChecked();
    exclusive_mode = true;
    writeTomlFile();
}

void KdASIOConfig::inputDeviceChanged(int idx)
{
    if (inputDeviceBox->count() == 0)
        return;
    // device has changed
    m_inputDeviceInfo = inputDeviceBox->itemData(idx).value<QAudioDevice>();
    inputDeviceName = m_inputDeviceInfo.description();
    writeTomlFile();
}

void KdASIOConfig::outputDeviceChanged(int idx)
{
    if (outputDeviceBox->count() == 0)
        return;
    // device has changed
    m_outputDeviceInfo = outputDeviceBox->itemData(idx).value<QAudioDevice>();
    outputDeviceName = m_outputDeviceInfo.description();
    writeTomlFile();
}

void KdASIOConfig::inputAudioSettClicked()
{
    // open Windows audio input settings control panel
    //FIXME - this process control does NOT work as Windows forks+kills the started process immediately? or something
    if (mmcplProc != nullptr) {
        mmcplProc->kill();
    }
    mmcplProc = new QProcess(this);
    mmcplProc->start("control", QStringList() << inputAudioSettPath);
}

void KdASIOConfig::outputAudioSettClicked()
{
    // open Windows audio output settings control panel
    //FIXME - this process control does NOT work as Windows forks+kills the started process immediately? or something
    if (mmcplProc != nullptr) {
        mmcplProc->kill();
    }
    mmcplProc = new QProcess(this);
    mmcplProc->start("control", QStringList() << outputAudioSettPath);
}


//void KdASIOConfig::bufferInfoClicked()
//{
//    QDialog *qd = new QDialog(this);
//    QLabel *qlab = new QLabel();
//    QString inputInfoText = "<b>" +
//                               tr ( "BUFFER SIZE - Tips" ) +
//                               "</b> " +
//                               "<br>" + "<br>" +
//                               "Select the size of the ASIO Buffer, by the number of samples. " +
//                               "<br>" + "<br>" +
//                               "A lower size may cause glitches in your sound, while higher size causes higher latency.";
//    qlab->setText(inputInfoText);
//    QVBoxLayout *layout = new QVBoxLayout();
//    layout->addWidget(qlab);
//    qd->setLayout(layout);
//    qd->setPalette(QPalette("#1d1f21"));
//    qd->show();
//}

void KdASIOConfig::koordLiveClicked()
{
    QDesktopServices::openUrl(QUrl("https://koord.live", QUrl::TolerantMode));
}

void KdASIOConfig::versionButtonClicked()
{
    QDesktopServices::openUrl(QUrl("https://github.com/koord-live/KoordASIO/releases", QUrl::TolerantMode));
}

void KdASIOConfig::githubClicked()
{
    QDesktopServices::openUrl(QUrl("https://github.com/koord-live/KoordASIO", QUrl::TolerantMode));
}
