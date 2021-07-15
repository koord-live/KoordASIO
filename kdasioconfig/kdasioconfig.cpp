/****************************************************************************
** KoordASIO
*/

#include "kdasioconfig.h"

// Utility functions for converting QAudioFormat fields into text

static QString toString(QAudioFormat::SampleType sampleType)
{
    QString result("Unknown");
    switch (sampleType) {
    case QAudioFormat::SignedInt:
        result = "SignedInt";
        break;
    case QAudioFormat::UnSignedInt:
        result = "UnSignedInt";
        break;
    case QAudioFormat::Float:
        result = "Float";
        break;
    case QAudioFormat::Unknown:
        result = "Unknown";
    }
    return result;
}

static QString toString(QAudioFormat::Endian endian)
{
    QString result("Unknown");
    switch (endian) {
    case QAudioFormat::LittleEndian:
        result = "LittleEndian";
        break;
    case QAudioFormat::BigEndian:
        result = "BigEndian";
        break;
    }
    return result;
}


KdASIOConfigBase::KdASIOConfigBase(QWidget *parent)
    : QMainWindow(parent)
{
    setupUi(this);
}

KdASIOConfigBase::~KdASIOConfigBase() {}


KdASIOConfig::KdASIOConfig(QWidget *parent)
    : KdASIOConfigBase(parent)
{
    connect(inputDeviceBox, QOverload<int>::of(&QComboBox::activated), this, &KdASIOConfig::inputDeviceChanged);
    connect(outputDeviceBox, QOverload<int>::of(&QComboBox::activated), this, &KdASIOConfig::outputDeviceChanged);

    inputDeviceBox->clear();
    const QAudio::Mode input_mode = QAudio::AudioInput;
    for (auto &deviceInfo: QAudioDeviceInfo::availableDevices(input_mode))
        inputDeviceBox->addItem(deviceInfo.deviceName(), QVariant::fromValue(deviceInfo));

    outputDeviceBox->clear();
    const QAudio::Mode output_mode = QAudio::AudioOutput;
    for (auto &deviceInfo: QAudioDeviceInfo::availableDevices(output_mode))
        outputDeviceBox->addItem(deviceInfo.deviceName(), QVariant::fromValue(deviceInfo));

    inputDeviceBox->setCurrentIndex(0);
    inputDeviceChanged(0);
    outputDeviceBox->setCurrentIndex(0);
    outputDeviceChanged(0);

    // parse FlexASIO.toml
    // only recognise our accepted INPUT values - the others are hardcoded
        //bufferSizeSamples = 480

        //[input]
        //device="default"
        //wasapiExclusiveMode = true|false

        //[output]
        //device="default"
        //wasapiExclusiveMode = true|false
}

void KdASIOConfig::writeTomlFile()
{

    // REF: https://github.com/dechamps/FlexASIO/blob/master/CONFIGURATION.md
    // JUST WRITE THIS TO FlexASIO.toml !
    // "
        //backend = "Windows WASAPI"
        //bufferSizeSamples = 480

        //[input]
        //device="default"
        //suggestedLatencySeconds = 0.0
        //wasapiExclusiveMode = true|false

        //[output]
        //device="default"
        //suggestedLatencySeconds = 0.0
        //wasapiExclusiveMode = true|false
    // "
}

void KdASIOConfig::bufferSizeChanged(int idx)
{
    // select from 32 , 64, 128, 256, 512, 1024, 2048
    // This a) gives a nice easy UI rather than choosing your own integer
    // AND b) makes it easier to do a live-refresh of the toml file,
    // THUS avoiding lots of spurious intermediate updates on buffer changes
}

void KdASIOConfig::exclusiveModeChanged()
{
    // select from true / false
}

void KdASIOConfig::inputDeviceChanged(int idx)
{

    if (inputDeviceBox->count() == 0)
        return;

    // device has changed
    m_inputDeviceInfo = inputDeviceBox->itemData(idx).value<QAudioDeviceInfo>();
}

void KdASIOConfig::outputDeviceChanged(int idx)
{

    if (outputDeviceBox->count() == 0)
        return;

    // device has changed
    m_outputDeviceInfo = outputDeviceBox->itemData(idx).value<QAudioDeviceInfo>();
}
