#!/usr/bin/python3

import sys
import scrapy
from scrapy.crawler import CrawlerProcess

from syzbot_scraper.spiders.syzbot import SyzbotSpider

if __name__ == "__main__":
    process = CrawlerProcess()
    process.crawl(SyzbotSpider, bugid=sys.argv[1])
    process.start()