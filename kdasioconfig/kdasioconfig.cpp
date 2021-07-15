/****************************************************************************
** KoordASIO
*/
#include <QFile>
#include <QTextStream>
#include "kdasioconfig.h"
#include "toml.h"
//#include <string>

#include <QDebug>


KdASIOConfigBase::KdASIOConfigBase(QWidget *parent)
    : QMainWindow(parent)
{
    setupUi(this);
}

KdASIOConfigBase::~KdASIOConfigBase() {}


KdASIOConfig::KdASIOConfig(QWidget *parent)
    : KdASIOConfigBase(parent)
{
    // set up signals
    connect(exclusiveButton, &QRadioButton::toggled, this, &KdASIOConfig::exclusiveModeChanged);
    connect(inputDeviceBox, QOverload<int>::of(&QComboBox::activated), this, &KdASIOConfig::inputDeviceChanged);
    connect(outputDeviceBox, QOverload<int>::of(&QComboBox::activated), this, &KdASIOConfig::outputDeviceChanged);
    connect(bufferSizeBox, QOverload<int>::of(&QComboBox::activated), this, &KdASIOConfig::bufferSizeChanged);

    // populate input device choices
    inputDeviceBox->clear();
    const QAudio::Mode input_mode = QAudio::AudioInput;
    for (auto &deviceInfo: QAudioDeviceInfo::availableDevices(input_mode))
        inputDeviceBox->addItem(deviceInfo.deviceName(), QVariant::fromValue(deviceInfo));

    // populate output device choices
    outputDeviceBox->clear();
    const QAudio::Mode output_mode = QAudio::AudioOutput;
    for (auto &deviceInfo: QAudioDeviceInfo::availableDevices(output_mode))
        outputDeviceBox->addItem(deviceInfo.deviceName(), QVariant::fromValue(deviceInfo));

    // Add standard bufferSize choices
    QStringList bufferSizes;
    bufferSizes << "32" << "64" << "128" << "256" << "512" << "1024" << "2048";
    bufferSizeBox->addItems(bufferSizes);

    // parse FlexASIO.toml
    std::ifstream ifs;
    ifs.exceptions ( std::ifstream::failbit | std::ifstream::badbit );
    try {
        ifs.open("/home/dan/code/KoordASIO/kdasioconfig/FlexASIO.toml", std::ifstream::in);
    }
    catch (std::ifstream::failure e) {
        qDebug("Failed to open file ...");
    }
    toml::ParseResult pr = toml::parse(ifs);
    qDebug("Parsed toml file");
    ifs.close();
    if (!pr.valid()) {
        // set defaults
        qInfo("Setting defaults");
        bufferSize = 64;
        exclusive_mode = false;
        inputDeviceName = "default";
        outputDeviceName = "default";
        // set stuff - up to 4 file updates in quick succession - problem ??
        bufferSizeBox->setCurrentText(QString::number(bufferSize));
        bufferSizeChanged(bufferSizeBox->currentIndex());
        inputDeviceBox->setCurrentText(inputDeviceName);
        inputDeviceChanged(inputDeviceBox->currentIndex());
        outputDeviceBox->setCurrentText(outputDeviceName);
        outputDeviceChanged(outputDeviceBox->currentIndex());
        exclusiveModeChanged();
    } else {
        qInfo("We have parsed a valid TOML file.");
        // only recognise our accepted INPUT values - the others are hardcoded
        const toml::Value& v = pr.value;
        // get bufferSize
        const toml::Value* bss = v.find("bufferSizeSamples");
        if (bss && bss->is<int>()) {
            if (bss->as<int>() == 32||64||128||256||512||1024||2048) {
                bufferSize = bss->as<int>();
            } else {
                bufferSize = 64;
            }
            bufferSizeBox->setCurrentText(QString::number(bufferSize));
            bufferSizeChanged(bufferSizeBox->currentIndex());
        }
        // get input stream stuff
        const toml::Value* input_dev = v.find("input.device");
        if (input_dev && input_dev->is<std::string>()) {
            // are we validating here at all?
            inputDeviceBox->setCurrentText(QString::fromStdString(input_dev->as<std::string>()));
            inputDeviceChanged(inputDeviceBox->currentIndex());
        } else {
            inputDeviceBox->setCurrentText("default");
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
            // are we validating here at all?
            outputDeviceBox->setCurrentText(QString::fromStdString(output_dev->as<std::string>()));
            outputDeviceChanged(outputDeviceBox->currentIndex());
        } else {
            outputDeviceBox->setCurrentText("default");
            outputDeviceChanged(outputDeviceBox->currentIndex());
        }
        const toml::Value* output_excl = v.find("output.wasapiExclusiveMode");
        if (output_excl && output_excl->is<bool>()) {
            exclusive_mode = output_excl->as<bool>();
        } else {
            exclusive_mode = false;
        }
        exclusiveButton->setChecked(exclusive_mode);
        exclusiveModeChanged();
    }
}

void KdASIOConfig::writeTomlFile()
{
    // REF: https://github.com/dechamps/FlexASIO/blob/master/CONFIGURATION.md
    // Write MINIMAL config to FlexASIO.toml, like this:
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
    QFile file("/home/dan//code/KoordASIO/kdasioconfig/FlexASIO.toml");
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text))
        return;
    QTextStream out(&file);
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
}

void KdASIOConfig::bufferSizeChanged(int idx)
{
    // select from 32 , 64, 128, 256, 512, 1024, 2048
    // This a) gives a nice easy UI rather than choosing your own integer
    // AND b) makes it easier to do a live-refresh of the toml file,
    // THUS avoiding lots of spurious intermediate updates on buffer changes
    bufferSize = bufferSizeBox->currentText().toInt();
    writeTomlFile();
}

void KdASIOConfig::exclusiveModeChanged()
{
    // select from true / false
    exclusive_mode = exclusiveButton->isChecked();
    writeTomlFile();
}

void KdASIOConfig::inputDeviceChanged(int idx)
{
    if (inputDeviceBox->count() == 0)
        return;
    // device has changed
    m_inputDeviceInfo = inputDeviceBox->itemData(idx).value<QAudioDeviceInfo>();
    inputDeviceName = m_inputDeviceInfo.deviceName();
    writeTomlFile();
}

void KdASIOConfig::outputDeviceChanged(int idx)
{
    if (outputDeviceBox->count() == 0)
        return;
    // device has changed
    m_outputDeviceInfo = outputDeviceBox->itemData(idx).value<QAudioDeviceInfo>();
    outputDeviceName = m_outputDeviceInfo.deviceName();
    writeTomlFile();
}
