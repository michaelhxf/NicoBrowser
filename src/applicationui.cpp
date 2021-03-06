/*
 * Copyright (c) 2011-2014 BlackBerry Limited.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include "applicationui.hpp"

#include <bb/cascades/Application>
#include <bb/cascades/QmlDocument>
#include <bb/cascades/AbstractPane>
#include <bb/cascades/LocaleHandler>
#include <bb/data/SqlDataAccess>

using namespace bb::cascades;
using namespace bb::data;

ApplicationUI::ApplicationUI() :
        QObject()
{
    // prepare the localization
    m_pTranslator = new QTranslator(this);
    m_pLocaleHandler = new LocaleHandler(this);

    bool res = QObject::connect(m_pLocaleHandler, SIGNAL(systemLanguageChanged()), this,
            SLOT(onSystemLanguageChanged()));
    // This is only available in Debug builds
    Q_ASSERT(res);
    // Since the variable is not used in the app, this is added to avoid a
    // compiler warning
    Q_UNUSED(res);

    // initial load
    onSystemLanguageChanged();

    // Create scene document from main.qml asset, the parent is set
    // to ensure the document gets destroyed properly at shut down.
    QmlDocument *qml = QmlDocument::create("asset:///main.qml").parent(this);
    qml->setContextProperty("nicobrowser", this);
    // Create root object for the UI
    AbstractPane *root = qml->createRootObject<AbstractPane>();

    // Set created root object as the application scene
    Application::instance()->setScene(root);
}

void ApplicationUI::onSystemLanguageChanged()
{
    QCoreApplication::instance()->removeTranslator(m_pTranslator);
    // Initiate, load and install the application translation files.
    QString locale_string = QLocale().name();
    QString file_name = QString("NicoBrowser_%1").arg(locale_string);
    if (m_pTranslator->load(file_name, "app/native/qm")) {
        QCoreApplication::instance()->installTranslator(m_pTranslator);
    }
}

bool ApplicationUI::initDatabase(bool forceInit)
{
    QString srcDBPath = QDir::currentPath() + "/app/native/assets/" + "/nbsetting.db";
    QString destDBPath = QDir::currentPath() + "/data/" + "nbsetting.db";

    if (QFile::exists(destDBPath)) {
        qDebug() << "database exist in data dir";
        if (forceInit) {
            QFile::remove(destDBPath);
            if (QFile::exists(destDBPath)) {
                qDebug() << "can't remove database in data dir";
            } else {
                qDebug() << "remove old database success";
            }
        }
    }

    //create own dir
    QDir dir; // New QDir objects default to the application working directory.
    dir.mkpath(QDir::currentPath() + "/shared/documents/nicobrowser");

    if (QFile::copy(srcDBPath, destDBPath)) {
        return true;
    } else {
        return false;
    }
}

QUrl ApplicationUI::getDatabasePath()
{
    QString destDBPath = QDir::currentPath() + "/data/" + "nbsetting.db";
    return QUrl(destDBPath);
}

bool ApplicationUI::importBookmark()
{
    QString filePath = QDir::currentPath() + "/shared/documents/nicobrowser/"
            + "nicobrowser_bookmark.txt";
    QFile textfile(filePath);
    SqlDataAccess sda(this->getDatabasePath().toString());

    if (textfile.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QTextStream stream(&textfile);
        QString line;
        do {
            line = stream.readLine();
            //qDebug() << line;
            QStringList list = line.split(",");
            if(list.size()>1){
                sda.execute("insert into bookmark (title, address) values ('"+list[0]+"','"+list[1]+"')");
                //qDebug()<<list[0]<<list[1];
            }
        } while (!line.isNull());
    }
    textfile.close();

    return true;
}

bool ApplicationUI::exportBookmark()
{
    SqlDataAccess sda(this->getDatabasePath().toString());
    QVariant result = sda.execute("select * from bookmark");
    QVariantList list = result.value<QVariantList>();

    QString filePath = QDir::currentPath() + "/shared/documents/nicobrowser/"
            + "nicobrowser_bookmark.txt";
    QFile textfile(filePath);
    textfile.open(QIODevice::WriteOnly | QIODevice::Text);
    QTextStream fout(&textfile);

    for (int i = 0; i < list.count(); i++) {
        //qDebug() << list[i].toMap()["title"].toString() << "," << list[i].toMap()["address"].toString() ;
        fout << list[i].toMap()["title"].toString() << "," << list[i].toMap()["address"].toString()
                << "\n";
    }
    textfile.close();

    //QString extPath = QDir::currentPath() + "/shared/documents/" + "nicobrowser_bookmark.txt";
    //qDebug() << filePath <<"\n"<< extPath;
//    if (QFile::copy(filePath, extPath)) {
//        return true;
//    } else {
//        return false;
//    }
    return true;
}
